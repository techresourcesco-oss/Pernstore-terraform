exports.up = (pgm) => {
  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'payment'
      ) THEN
        CREATE TYPE public.payment AS ENUM ('PAYSTACK', 'STRIPE');
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
      ) THEN
        CREATE TABLE public.users (
          user_id SERIAL NOT NULL,
          password character varying(200),
          email character varying(100) UNIQUE NOT NULL,
          fullname character varying(100) NOT NULL,
          username character varying(50) UNIQUE NOT NULL,
          google_id character varying(100) UNIQUE,
          roles character varying(10)[] DEFAULT '{customer}'::character varying[] NOT NULL,
          address character varying(200),
          city character varying(100),
          state character varying(100),
          country character varying(100),
          created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (user_id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'products'
      ) THEN
        CREATE TABLE public.products (
          product_id SERIAL NOT NULL,
          name character varying(100) NOT NULL UNIQUE,
          slug character varying(100) NOT NULL UNIQUE,
          price real NOT NULL,
          description text NOT NULL,
          image_url character varying,
          PRIMARY KEY (product_id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'cart'
      ) THEN
        CREATE TABLE public.cart (
          id SERIAL NOT NULL,
          user_id integer UNIQUE NOT NULL,
          PRIMARY KEY (id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'cart_item'
      ) THEN
        CREATE TABLE public.cart_item (
          id SERIAL NOT NULL,
          cart_id integer NOT NULL,
          product_id integer NOT NULL,
          quantity integer NOT NULL CHECK (quantity > 0),
          PRIMARY KEY (id),
          UNIQUE (cart_id, product_id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'orders'
      ) THEN
        CREATE TABLE public.orders (
          order_id SERIAL NOT NULL,
          user_id integer NOT NULL,
          status character varying(20) NOT NULL,
          date timestamp without time zone DEFAULT CURRENT_DATE NOT NULL,
          amount real,
          total integer,
          ref character varying(100),
          payment_method public.payment,
          PRIMARY KEY (order_id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'order_item'
      ) THEN
        CREATE TABLE public.order_item (
          id SERIAL NOT NULL,
          order_id integer NOT NULL,
          product_id integer NOT NULL,
          quantity integer NOT NULL,
          PRIMARY KEY (id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'resetTokens'
      ) THEN
        CREATE TABLE public."resetTokens" (
          id SERIAL NOT NULL,
          email character varying NOT NULL,
          token character varying NOT NULL,
          used boolean DEFAULT false NOT NULL,
          expiration timestamp without time zone,
          PRIMARY KEY (id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'reviews'
      ) THEN
        CREATE TABLE public.reviews (
          user_id integer NOT NULL,
          content text NOT NULL,
          rating integer NOT NULL,
          product_id integer NOT NULL,
          date date NOT NULL,
          id integer NOT NULL,
          PRIMARY KEY (user_id, product_id)
        );
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'cart_user_id_fkey'
      ) THEN
        ALTER TABLE public.cart
          ADD CONSTRAINT cart_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES public.users (user_id)
          ON DELETE SET NULL;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'cart_item_cart_id_fkey'
      ) THEN
        ALTER TABLE public.cart_item
          ADD CONSTRAINT cart_item_cart_id_fkey
          FOREIGN KEY (cart_id)
          REFERENCES public.cart (id)
          ON DELETE CASCADE;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'cart_item_product_id_fkey'
      ) THEN
        ALTER TABLE public.cart_item
          ADD CONSTRAINT cart_item_product_id_fkey
          FOREIGN KEY (product_id)
          REFERENCES public.products (product_id)
          ON DELETE SET NULL;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'order_item_order_id_fkey'
      ) THEN
        ALTER TABLE public.order_item
          ADD CONSTRAINT order_item_order_id_fkey
          FOREIGN KEY (order_id)
          REFERENCES public.orders (order_id)
          ON DELETE CASCADE;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'order_item_product_id_fkey'
      ) THEN
        ALTER TABLE public.order_item
          ADD CONSTRAINT order_item_product_id_fkey
          FOREIGN KEY (product_id)
          REFERENCES public.products (product_id)
          ON DELETE SET NULL;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'orders_user_id_fkey'
      ) THEN
        ALTER TABLE public.orders
          ADD CONSTRAINT orders_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES public.users (user_id)
          ON DELETE CASCADE;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'reviews_product_id_fkey'
      ) THEN
        ALTER TABLE public.reviews
          ADD CONSTRAINT reviews_product_id_fkey
          FOREIGN KEY (product_id)
          REFERENCES public.products (product_id)
          ON DELETE SET NULL;
      END IF;
    END $$;
  `);

  pgm.sql(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'reviews_user_id_fkey'
      ) THEN
        ALTER TABLE public.reviews
          ADD CONSTRAINT reviews_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES public.users (user_id)
          ON DELETE SET NULL;
      END IF;
    END $$;
  `);

  pgm.sql(`
    CREATE UNIQUE INDEX IF NOT EXISTS users_unique_lower_email_idx
      ON public.users (lower(email));
  `);

  pgm.sql(`
    CREATE UNIQUE INDEX IF NOT EXISTS users_unique_lower_username_idx
      ON public.users (lower(username));
  `);
};

exports.down = () => {
  // Intentionally no-op to avoid destructive data loss during a rollback.
};
