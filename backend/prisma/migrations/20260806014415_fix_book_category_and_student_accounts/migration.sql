/*
  Warnings:

  - You are about to drop the column `BookCategory` on the `books` table. All the data in the column will be lost.
  - Added the required column `category` to the `books` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "books" DROP COLUMN "BookCategory",
ADD COLUMN     "category" "BookCategory" NOT NULL;

-- AlterTable
ALTER TABLE "loans" ADD COLUMN     "extension_count" INTEGER NOT NULL DEFAULT 0;

-- RenameForeignKey
ALTER TABLE "users" RENAME CONSTRAINT "user_student_id_fkey" TO "users_student_id_fkey";

-- RenameIndex
ALTER INDEX "user_student_id_key" RENAME TO "users_student_id_key";
