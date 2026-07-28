-- CreateEnum
CREATE TYPE "DeviceType" AS ENUM ('ABSENSI', 'PERPUSTAKAAN');

-- CreateEnum
CREATE TYPE "BookCategory" AS ENUM ('UMUM', 'PELAJARAN');

-- CreateEnum
CREATE TYPE "BookStatus" AS ENUM ('TERSEDIA', 'DIPINJAM');

-- CreateEnum
CREATE TYPE "LoanStatus" AS ENUM ('DIPINJAM', 'DIKEMBALIKAN');

-- AlterEnum
ALTER TYPE "UserRole" ADD VALUE 'pustakawan';

-- AlterTable
ALTER TABLE "devices" ADD COLUMN     "device_type" "DeviceType" NOT NULL DEFAULT 'ABSENSI';

-- CreateTable
CREATE TABLE "books" (
    "id" SERIAL NOT NULL,
    "barcode" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "BookCategory" "BookCategory" NOT NULL,
    "status" "BookStatus" NOT NULL DEFAULT 'TERSEDIA',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "books_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "loans" (
    "id" SERIAL NOT NULL,
    "book_id" INTEGER NOT NULL,
    "rfid_uid" TEXT NOT NULL,
    "borrowed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "due_date" TIMESTAMP(3) NOT NULL,
    "returned_at" TIMESTAMP(3),
    "status" "LoanStatus" NOT NULL DEFAULT 'DIPINJAM',
    "overdue_days" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "loans_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "books_barcode_key" ON "books"("barcode");

-- CreateIndex
CREATE INDEX "loans_status_idx" ON "loans"("status");

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_book_id_fkey" FOREIGN KEY ("book_id") REFERENCES "books"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_rfid_uid_fkey" FOREIGN KEY ("rfid_uid") REFERENCES "student_credentials"("rfid_uid") ON DELETE RESTRICT ON UPDATE CASCADE;
