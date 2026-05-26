-- AlterTable
ALTER TABLE "product_review" ADD COLUMN     "moderation_status" VARCHAR(20) NOT NULL DEFAULT 'pending';
