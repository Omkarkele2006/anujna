import { prisma } from '../src/lib/prisma';

const defaultRoles = [
  {
    roleName: 'ADMIN',
    description: 'System Administrator with full platform management, user verification, and audit privileges.',
  },
  {
    roleName: 'DOCTOR',
    description: 'Verified Healthcare Provider with patient record viewing and medical request privileges.',
  },
  {
    roleName: 'PATIENT',
    description: 'Healthcare Consumer with full ownership and consent governance over personal health data.',
  },
];

async function main() {
  console.log('Seeding system roles into database...');

  for (const role of defaultRoles) {
    const upsertedRole = await prisma.role.upsert({
      where: { roleName: role.roleName },
      update: { description: role.description },
      create: {
        roleName: role.roleName,
        description: role.description,
      },
    });
    console.log(`- Role seeded: ${upsertedRole.roleName} (ID: ${upsertedRole.roleId})`);
  }

  console.log('Database seeding completed successfully.');
}

main()
  .catch((e) => {
    console.error('Error during database seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
