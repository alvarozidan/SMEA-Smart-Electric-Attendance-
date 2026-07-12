/*
  Warnings:

  - The `revoked_at` column on the `refresh_tokens` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - Changed the type of `expires_at` on the `refresh_tokens` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- AlterTable
ALTER TABLE "refresh_tokens" DROP COLUMN "expires_at",
ADD COLUMN     "expires_at" TIMESTAMP(3) NOT NULL,
DROP COLUMN "revoked_at",
ADD COLUMN     "revoked_at" TIMESTAMP(3);
