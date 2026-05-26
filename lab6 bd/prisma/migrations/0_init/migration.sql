-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateTable
CREATE TABLE "bot_command" (
    "command_id" SERIAL NOT NULL,
    "command_name" VARCHAR(50) NOT NULL,
    "description" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "bot_command_pkey" PRIMARY KEY ("command_id")
);

-- CreateTable
CREATE TABLE "bot_order" (
    "order_id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "promo_code_id" INTEGER,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "total_amount" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "status_id" INTEGER NOT NULL,

    CONSTRAINT "bot_order_pkey" PRIMARY KEY ("order_id")
);

-- CreateTable
CREATE TABLE "bot_user" (
    "user_id" SERIAL NOT NULL,
    "telegram_id" BIGINT NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "role" VARCHAR(20) NOT NULL DEFAULT 'user',
    "status" VARCHAR(20) NOT NULL DEFAULT 'active',
    "registered_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "balance" DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT "bot_user_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "command_execution" (
    "execution_id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "command_id" INTEGER NOT NULL,
    "executed_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "result_status" VARCHAR(20) NOT NULL,

    CONSTRAINT "command_execution_pkey" PRIMARY KEY ("execution_id")
);

-- CreateTable
CREATE TABLE "order_item" (
    "order_item_id" SERIAL NOT NULL,
    "order_id" INTEGER NOT NULL,
    "product_id" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" DECIMAL(10,2) NOT NULL,
    "line_total" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "order_item_pkey" PRIMARY KEY ("order_item_id")
);

-- CreateTable
CREATE TABLE "order_status" (
    "status_id" SERIAL NOT NULL,
    "name" VARCHAR(20) NOT NULL,

    CONSTRAINT "order_status_pkey" PRIMARY KEY ("status_id")
);

-- CreateTable
CREATE TABLE "payment" (
    "payment_id" SERIAL NOT NULL,
    "order_id" INTEGER NOT NULL,
    "amount" DECIMAL(10,2) NOT NULL,
    "paid_at" TIMESTAMP(6),
    "method_id" INTEGER NOT NULL,
    "status_id" INTEGER NOT NULL,

    CONSTRAINT "payment_pkey" PRIMARY KEY ("payment_id")
);

-- CreateTable
CREATE TABLE "payment_method" (
    "method_id" SERIAL NOT NULL,
    "name" VARCHAR(30) NOT NULL,

    CONSTRAINT "payment_method_pkey" PRIMARY KEY ("method_id")
);

-- CreateTable
CREATE TABLE "payment_status" (
    "status_id" SERIAL NOT NULL,
    "name" VARCHAR(20) NOT NULL,

    CONSTRAINT "payment_status_pkey" PRIMARY KEY ("status_id")
);

-- CreateTable
CREATE TABLE "product" (
    "product_id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "price" DECIMAL(10,2) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "product_type_id" INTEGER NOT NULL,

    CONSTRAINT "product_pkey" PRIMARY KEY ("product_id")
);

-- CreateTable
CREATE TABLE "product_type" (
    "product_type_id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,

    CONSTRAINT "product_type_pkey" PRIMARY KEY ("product_type_id")
);

-- CreateTable
CREATE TABLE "promo_code" (
    "promo_code_id" SERIAL NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "discount_type" VARCHAR(20) NOT NULL,
    "discount_value" DECIMAL(10,2) NOT NULL,
    "starts_at" TIMESTAMP(6) NOT NULL,
    "ends_at" TIMESTAMP(6) NOT NULL,

    CONSTRAINT "promo_code_pkey" PRIMARY KEY ("promo_code_id")
);

-- CreateTable
CREATE TABLE "publication" (
    "publication_id" SERIAL NOT NULL,
    "author_id" INTEGER NOT NULL,
    "title" VARCHAR(150) NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "publication_pkey" PRIMARY KEY ("publication_id")
);

-- CreateTable
CREATE TABLE "publication_tag" (
    "publication_id" INTEGER NOT NULL,
    "tag_id" INTEGER NOT NULL,

    CONSTRAINT "pk_publication_tag" PRIMARY KEY ("publication_id","tag_id")
);

-- CreateTable
CREATE TABLE "referral" (
    "referral_id" SERIAL NOT NULL,
    "referrer_id" INTEGER NOT NULL,
    "referred_id" INTEGER NOT NULL,
    "reward_amount" DECIMAL(10,2) NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "referral_pkey" PRIMARY KEY ("referral_id")
);

-- CreateTable
CREATE TABLE "tag" (
    "tag_id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,

    CONSTRAINT "tag_pkey" PRIMARY KEY ("tag_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "bot_command_command_name_key" ON "bot_command"("command_name");

-- CreateIndex
CREATE UNIQUE INDEX "bot_user_telegram_id_key" ON "bot_user"("telegram_id");

-- CreateIndex
CREATE UNIQUE INDEX "bot_user_username_key" ON "bot_user"("username");

-- CreateIndex
CREATE UNIQUE INDEX "uq_order_item_order_product" ON "order_item"("order_id", "product_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_status_name_key" ON "order_status"("name");

-- CreateIndex
CREATE UNIQUE INDEX "payment_order_id_key" ON "payment"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_method_name_key" ON "payment_method"("name");

-- CreateIndex
CREATE UNIQUE INDEX "payment_status_name_key" ON "payment_status"("name");

-- CreateIndex
CREATE UNIQUE INDEX "product_type_name_key" ON "product_type"("name");

-- CreateIndex
CREATE UNIQUE INDEX "promo_code_code_key" ON "promo_code"("code");

-- CreateIndex
CREATE UNIQUE INDEX "referral_referred_id_key" ON "referral"("referred_id");

-- CreateIndex
CREATE UNIQUE INDEX "tag_name_key" ON "tag"("name");

-- AddForeignKey
ALTER TABLE "bot_order" ADD CONSTRAINT "fk_bot_order_promo_code" FOREIGN KEY ("promo_code_id") REFERENCES "promo_code"("promo_code_id") ON DELETE SET NULL ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "bot_order" ADD CONSTRAINT "fk_bot_order_status" FOREIGN KEY ("status_id") REFERENCES "order_status"("status_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "bot_order" ADD CONSTRAINT "fk_bot_order_user" FOREIGN KEY ("user_id") REFERENCES "bot_user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "command_execution" ADD CONSTRAINT "fk_command_execution_command" FOREIGN KEY ("command_id") REFERENCES "bot_command"("command_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "command_execution" ADD CONSTRAINT "fk_command_execution_user" FOREIGN KEY ("user_id") REFERENCES "bot_user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item" ADD CONSTRAINT "fk_order_item_order" FOREIGN KEY ("order_id") REFERENCES "bot_order"("order_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item" ADD CONSTRAINT "fk_order_item_product" FOREIGN KEY ("product_id") REFERENCES "product"("product_id") ON DELETE RESTRICT ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "payment" ADD CONSTRAINT "fk_payment_method" FOREIGN KEY ("method_id") REFERENCES "payment_method"("method_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "payment" ADD CONSTRAINT "fk_payment_order" FOREIGN KEY ("order_id") REFERENCES "bot_order"("order_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "payment" ADD CONSTRAINT "fk_payment_status" FOREIGN KEY ("status_id") REFERENCES "payment_status"("status_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "product" ADD CONSTRAINT "fk_product_product_type" FOREIGN KEY ("product_type_id") REFERENCES "product_type"("product_type_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "publication" ADD CONSTRAINT "fk_publication_author" FOREIGN KEY ("author_id") REFERENCES "bot_user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "publication_tag" ADD CONSTRAINT "fk_publication_tag_publication" FOREIGN KEY ("publication_id") REFERENCES "publication"("publication_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "publication_tag" ADD CONSTRAINT "fk_publication_tag_tag" FOREIGN KEY ("tag_id") REFERENCES "tag"("tag_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "referral" ADD CONSTRAINT "fk_referral_referred" FOREIGN KEY ("referred_id") REFERENCES "bot_user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "referral" ADD CONSTRAINT "fk_referral_referrer" FOREIGN KEY ("referrer_id") REFERENCES "bot_user"("user_id") ON DELETE CASCADE ON UPDATE NO ACTION;
