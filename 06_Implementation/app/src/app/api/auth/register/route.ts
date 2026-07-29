import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { hashPassword } from "@/lib/auth/password";
import { validateEmail, validatePassword } from "@/lib/auth/validation";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { fullName, email, password, roleName } = body;

    // 1. Basic Required Field Checks
    if (!fullName || typeof fullName !== "string" || !fullName.trim()) {
      return NextResponse.json(
        { error: "Full name is required." },
        { status: 400 }
      );
    }

    // 2. Normalize and Validate Email
    const normalizedEmail = email ? String(email).trim().toLowerCase() : "";
    const emailValidation = validateEmail(normalizedEmail);
    if (!emailValidation.isValid) {
      return NextResponse.json(
        { error: emailValidation.errors[0] },
        { status: 400 }
      );
    }

    // 3. Validate Password Complexity (OWASP standard)
    const passwordValidation = validatePassword(password || "");
    if (!passwordValidation.isValid) {
      return NextResponse.json(
        { errors: passwordValidation.errors },
        { status: 400 }
      );
    }

    // 4. Validate Allowed Self-Registration Roles (Prevent Admin privilege escalation)
    const allowedRoles = ["PATIENT", "DOCTOR"];
    const targetRole = String(roleName || "PATIENT").toUpperCase();

    if (!allowedRoles.includes(targetRole)) {
      return NextResponse.json(
        { error: "Invalid role specified for self-registration." },
        { status: 400 }
      );
    }

    // 5. Check if User Already Exists
    const existingUser = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (existingUser) {
      return NextResponse.json(
        { error: "An account with this email address already exists." },
        { status: 409 } // 409 Conflict
      );
    }

    // 6. Verify Target Role Exists in Database
    const roleRecord = await prisma.role.findUnique({
      where: { roleName: targetRole },
    });

    if (!roleRecord) {
      return NextResponse.json(
        { error: `System role '${targetRole}' not found.` },
        { status: 500 }
      );
    }

    // 7. Secure Password Hashing
    const passwordHash = await hashPassword(password);

    // 8. Atomic Database Transaction (Create User + Assign UserRole)
    const newUser = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          fullName: fullName.trim(),
          email: normalizedEmail,
          passwordHash,
          accountStatus: "ACTIVE",
        },
      });

      await tx.userRole.create({
        data: {
          userId: user.userId,
          roleId: roleRecord.roleId,
        },
      });

      return user;
    });

    // 9. Return Sanitized Response (Excluding password hash)
    return NextResponse.json(
      {
        message: "User registered successfully.",
        user: {
          userId: newUser.userId,
          fullName: newUser.fullName,
          email: newUser.email,
          accountStatus: newUser.accountStatus,
          role: targetRole,
          createdAt: newUser.createdAt,
        },
      },
      { status: 201 } // 201 Created
    );
  } catch (error) {
    console.error("Error in registration API route:", error);
    return NextResponse.json(
      { error: "An unexpected error occurred during registration." },
      { status: 500 }
    );
  }
}
