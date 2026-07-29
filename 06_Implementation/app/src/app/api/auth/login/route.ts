import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { comparePassword } from "@/lib/auth/password";
import { signAccessToken } from "@/lib/auth/jwt";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { email, password } = body;

    // 1. Basic Field Validation
    if (!email || !password) {
      return NextResponse.json(
        { error: "Email and password are required." },
        { status: 400 }
      );
    }

    const normalizedEmail = String(email).trim().toLowerCase();

    // 2. Query User & Associated Roles
    const user = await prisma.user.findUnique({
      where: { email: normalizedEmail },
      include: {
        userRoles: {
          include: {
            role: true,
          },
        },
      },
    });

    // Generic error message for Account Enumeration Prevention
    const INVALID_CREDENTIALS_ERROR = "Invalid email or password.";

    // 3. User Existence Check
    if (!user) {
      return NextResponse.json(
        { error: INVALID_CREDENTIALS_ERROR },
        { status: 401 }
      );
    }

    // 4. Timing-Safe Password Comparison
    const isPasswordValid = await comparePassword(password, user.passwordHash);
    if (!isPasswordValid) {
      return NextResponse.json(
        { error: INVALID_CREDENTIALS_ERROR },
        { status: 401 }
      );
    }

    // 5. Account Status Verification
    if (user.accountStatus !== "ACTIVE") {
      return NextResponse.json(
        { error: "Your account is currently suspended or inactive." },
        { status: 403 }
      );
    }

    // 6. Extract User Roles
    const roles = user.userRoles.map((ur) => ur.role.roleName);

    // 7. Sign JWT Access Token
    const token = await signAccessToken({
      userId: user.userId,
      email: user.email,
      roles,
    });

    // 8. Construct Response Payload (Excluding password hash)
    const response = NextResponse.json(
      {
        message: "Login successful.",
        user: {
          userId: user.userId,
          fullName: user.fullName,
          email: user.email,
          accountStatus: user.accountStatus,
          roles,
        },
      },
      { status: 200 }
    );

    // 9. Set Secure HTTP-Only Cookie
    response.cookies.set("anujna_token", token, {
      httpOnly: true, // Prevents XSS cookie theft via client-side JavaScript
      secure: process.env.NODE_ENV === "production", // Enforces HTTPS in production
      sameSite: "lax", // Protects against CSRF attacks
      maxAge: 15 * 60, // 15 minutes (900 seconds)
      path: "/",
    });

    return response;
  } catch (error) {
    console.error("Error in login API route:", error);
    return NextResponse.json(
      { error: "An unexpected error occurred during login." },
      { status: 500 }
    );
  }
}
