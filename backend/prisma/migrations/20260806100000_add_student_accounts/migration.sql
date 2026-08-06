ALTER TYPE "UserRole" ADD VALUE 'murid';

ALTER TABLE "users" ALTER COLUMN "email" DROP NOT NULL;
ALTER TABLE "users" ADD COLUMN "must_change_password" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "users" ADD COLUMN "student_id" INTEGER;

CREATE UNIQUE INDEX "user_student_id_key" ON "users"("student_id");

ALTER TABLE "users" ADD CONSTRAINT "user_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "students"("id") ON DELETE SET NULL ON UPDATE CASCADE;