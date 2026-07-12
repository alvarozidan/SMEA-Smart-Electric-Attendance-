const { PrismaClient } = require("../generated/prisma");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
    const passwordHash = await bcrypt.hash("admin123", 10);

    const admin = await prisma.user.upsert({
        where: { email: "admin@sekolah.test" },
        update: {},
        create: {
            name: "Admin Utama",
            email : "admin@sekolah.test",
            passwordHash,
            role: "admin",
        },
    });

    console.log("Seed selesai: ", admin.email);
}

main()
    .catch((err) => {
        console.error(err);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });