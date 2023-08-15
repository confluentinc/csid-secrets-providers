--
-- Trust Service cts schema
-- Owner: #oauth-eng
--

SET TIME ZONE 'UTC';
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

DO $$
BEGIN
  CREATE USER cc_cts_api;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_cts_api already exists -- skip create';
END
$$;

CREATE SCHEMA cts;

---
--- Custom Types
---
CREATE DOMAIN cts.SAFE_URL AS text CHECK (VALUE ~ '^(https://|vault://|file://")?[a-z0-9]+([-.]{1}[a-z0-9]+)*.[a-z]+(:[0-9]{1,5})?(/.*)?$');

CREATE TYPE cts.status AS ENUM ('active', 'inactive', 'deleted');

--
-- https://github.com/confluentinc/cc-utils/blob/master/idgen/idgenerator.go
--
CREATE DOMAIN cts.RESOURCE_ID AS text CHECK (VALUE ~ '^([a-z]+)-([a-zA-Z0-9]+)$');

---
--- Supported Identity Assertion Providers
---
CREATE TABLE IF NOT EXISTS cts.supported_identity_providers (
    id              integer PRIMARY KEY,
    display_name    TEXT NOT NULL,
    description     TEXT
);

INSERT INTO cts.supported_identity_providers (id, display_name, description)
VALUES
    (1, 'openid', 'OpenID Identity Provider')
ON CONFLICT DO NOTHING;

---
--- Sequence Generators
---
CREATE SEQUENCE IF NOT EXISTS cts.identity_provider_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS cts.identity_pool_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS cts.scope_mapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS cts.role_policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

---
--- OpenId compatible Identity Provider
---
CREATE TABLE cts.identity_provider (
  id cts.RESOURCE_ID PRIMARY KEY,
  issuer_uri TEXT NOT NULL,
  jwks_uri TEXT NOT NULL,
  keys JSONB NOT NULL DEFAULT '{}',
  jwks_updated TIMESTAMP without TIME ZONE,
  jwks_refresh_interval INTERVAL NOT NULL DEFAULT '1 00:00:00',
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  created_by TEXT NOT NULL,
  modified_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  modified_by TEXT NOT NULL,
  deactivated boolean DEFAULT false NOT NULL,
  deactivated_at TIMESTAMP without TIME ZONE,
  last_change_id BIGINT NOT NULL default 1
);

CREATE UNIQUE INDEX identity_provider_last_change_id_idx ON cts.identity_provider USING btree (last_change_id);
CREATE UNIQUE INDEX identity_provider_issuer_jwks_idx ON cts.identity_provider USING btree (issuer_uri, jwks_uri) WHERE (deactivated = false);
CREATE INDEX identity_provider_deactivated_at ON cts.identity_provider (deactivated_at);

---
--- Identity Provider Scope Mapping
---
CREATE TABLE cts.provider_org_mapping (
  id cts.RESOURCE_ID NOT NULL,
  provider_id cts.RESOURCE_ID NOT NULL,
  name CHARACTER VARYING(64) NOT NULL,
  description TEXT,
  organization_id text NOT NULL,
  status cts.STATUS NOT NULL DEFAULT 'active',
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  created_by TEXT NOT NULL,
  modified_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  modified_by TEXT NOT NULL,
  last_change_id BIGINT NOT NULL default 1,
  FOREIGN KEY (provider_id) REFERENCES cts.identity_provider(id)
);

CREATE UNIQUE INDEX provider_org_mapping_last_change_id_idx ON cts.provider_org_mapping USING btree (last_change_id);
CREATE UNIQUE INDEX provider_org_mapping_scope_idx ON cts.provider_org_mapping (provider_id, organization_id) WHERE (status = 'active');
--- TODO: Uncomment after postgres updates to 12+
--- CREATE INDEX provider_org_mapping_org_idx ON cts.provider_org_mapping (organization_id) include (status);

---
--- Identity Pool
---
CREATE TABLE cts.identity_pool (
  id cts.RESOURCE_ID PRIMARY KEY,
  provider_id cts.RESOURCE_ID NOT NULL,
  name CHARACTER VARYING(64) NOT NULL,
  description TEXT,
  issuer_uri TEXT NOT NULL,
  subject_claim TEXT DEFAULT 'sub' NOT NULL,
  conditions TEXT,
  service_account_id cts.RESOURCE_ID NOT NULL,
  organization_id text NOT NULL,
  status cts.STATUS DEFAULT 'active' NOT NULL,
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  created_by TEXT NOT NULL,
  modified_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  modified_by TEXT NOT NULL,
  last_change_id BIGINT NOT NULL default 1,
  FOREIGN KEY (provider_id) REFERENCES cts.identity_provider(id)
);

CREATE UNIQUE INDEX identity_pool_last_change_id_idx ON cts.identity_pool USING btree (last_change_id);
CREATE INDEX identity_pool_provider_scope_idx ON cts.identity_pool (provider_id, organization_id);
--- TODO: Uncomment after postgres updates to 12+
--- CREATE INDEX identity_pool_org_idx ON cts.identity_pool (organization_id) include (status);

---
--- Role
---
CREATE TABLE cts.role_policy (
  id cts.RESOURCE_ID PRIMARY KEY,
  name CHARACTER VARYING(64) NOT NULL,
  description TEXT,
  organization_id text NOT NULL,
  status cts.STATUS DEFAULT 'active' NOT NULL,
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  created_by TEXT NOT NULL,
  modified_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  modified_by TEXT NOT NULL,
  last_change_id BIGINT NOT NULL default 1
);

CREATE UNIQUE INDEX role_policy_last_change_id_idx ON cts.role_policy USING btree(last_change_id);
--- TODO: Uncomment after postgres updates to 12+
--- CREATE INDEX role_policy_org_idx ON cts.role_policy (organization_id) include (status);

---
--- Sets modified_on column to now
---
CREATE OR REPLACE FUNCTION cts.modified_on_func()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NEW.last_change_id = nextval(format('cts.%s_last_change_id_seq', TG_TABLE_NAME));
        NEW.modified_at = NOW();
        RETURN NEW;
    END $$;


---
--- Attach modified_on_trg to each table with a modified_on column in the deployment schema.
---
DO
'
    DECLARE
        t text;
    BEGIN
        FOR t IN
            SELECT table_name
            FROM information_schema.columns
            WHERE column_name = ''modified_at''
        LOOP
            EXECUTE format(''
                CREATE SEQUENCE IF NOT EXISTS cts.%s_last_change_id_seq
                    START WITH 1
                    INCREMENT BY 1
                    NO MINVALUE
                    NO MAXVALUE
                    CACHE 1 '', t);
            EXECUTE format(''
                CREATE TRIGGER %s_modified_on_trg
                    BEFORE INSERT OR UPDATE ON cts.%s
                    FOR EACH ROW
                    WHEN (pg_trigger_depth() < 1)
                    EXECUTE PROCEDURE cts.modified_on_func()'', t, t);
        END loop;
    END;
' language 'plpgsql';

--
-- Name: trust_extractor_publisher_state; Type: TABLE; Schema: cts; Owner: -
--

CREATE TABLE cts.trust_extractor_publisher_state (
    provider_kafka_message_sequence_id bigint NOT NULL,
    provider_last_change_id bigint NOT NULL,
    provider_org_mapping_last_change_id bigint NOT NULL,
    idp_pool_kafka_message_sequence_id bigint NOT NULL,
    idp_pool_last_change_id bigint NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    publish_type text,
    PRIMARY KEY (provider_kafka_message_sequence_id, idp_pool_kafka_message_sequence_id)
);


--
-- Name: provider_kafka_message_sequence_id; Type: SEQUENCE; Schema: cts; Owner: -
--

CREATE SEQUENCE cts.provider_kafka_message_sequence_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: idp_pool_kafka_message_sequence_id; Type: SEQUENCE; Schema: cts; Owner: -
--

CREATE SEQUENCE cts.idp_pool_kafka_message_sequence_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: extractor_provider_last_change_id_idx; Type: INDEX; Schema: cts; Owner: -
--

CREATE INDEX extractor_provider_last_change_id_idx ON cts.trust_extractor_publisher_state USING btree (provider_last_change_id);


--
-- Name: extractor_provider_org_mapping_last_change_id_idx; Type: INDEX; Schema: cts; Owner: -
--

CREATE INDEX extractor_provider_org_mapping_last_change_id_idx ON cts.trust_extractor_publisher_state USING btree (provider_org_mapping_last_change_id);

--
-- Name: extractor_events_kafka_log_idp_pool_last_change_id_idx; Type: INDEX; Schema: cts; Owner: -
--

CREATE INDEX extractor_idp_pool_last_change_id_idx ON cts.trust_extractor_publisher_state USING btree (idp_pool_last_change_id);


--
-- Name: scheduler_events_id_seq; Type: SEQUENCE; Schema: cts; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS cts.scheduler_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: jwks_scheduler_state; Type: TABLE; Schema: cts; Owner: -
--

CREATE TABLE cts.jwks_scheduler_state (
    scheduler_events_sequence_id bigint NOT NULL PRIMARY KEY,
    provider_last_change_id bigint NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL
);

--
-- Name: scheduler_events_provider_last_change_id_idx; Type: INDEX; Schema: cts; Owner: -
--

CREATE INDEX scheduler_events_provider_last_change_id_idx ON cts.jwks_scheduler_state USING btree (provider_last_change_id);


--
-- Name: jwks_refresh_stat; Type: TABLE; Schema: cts; Owner: -
--

CREATE TABLE cts.jwks_refresh_stat (
    id cts.RESOURCE_ID PRIMARY KEY,
    last_success_refresh TIMESTAMP without TIME ZONE,
    last_failure_refresh TIMESTAMP without TIME ZONE,
    num_retries_since_last_success int,
    FOREIGN KEY (id) REFERENCES cts.identity_provider(id)
);

--- TODO: Uncomment after postgres updates to 12+
--- CREATE PUBLICATION p_upgrade FOR ALL TABLES WITH (publish = 'insert, update, delete, truncate');

ALTER TABLE cts.provider_org_mapping ADD PRIMARY KEY (id);

GRANT USAGE ON SCHEMA cts TO cc_cts_api;
-- Don't grant DELETE, because we only allow soft deletes
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA cts TO cc_cts_api;
-- This lets this user advance with nextval (for inserts in tables using this) but not reset it
GRANT USAGE ON ALL SEQUENCES IN SCHEMA cts TO cc_cts_api;
ALTER DEFAULT PRIVILEGES IN SCHEMA cts GRANT SELECT, INSERT, UPDATE ON TABLES TO cc_cts_api;
ALTER DEFAULT PRIVILEGES IN SCHEMA cts GRANT USAGE ON SEQUENCES TO cc_cts_api;

ALTER TABLE cts.jwks_refresh_stat ADD COLUMN last_failure_refresh_error TEXT;

CREATE TYPE cts.identity_pool_type AS ENUM ('OIDC', 'SSO');
ALTER TABLE cts.identity_pool ADD COLUMN type cts.identity_pool_type NOT NULL DEFAULT 'OIDC';

ALTER TABLE cts.identity_pool ALTER COLUMN provider_id DROP NOT NULL;

ALTER TABLE cts.identity_pool ALTER COLUMN issuer_uri DROP NOT NULL;
ALTER TABLE cts.identity_pool ALTER COLUMN subject_claim DROP NOT NULL;

-- Add column for storing customer-facing IdP ID - "customer_provider_id"
ALTER TABLE cts.provider_org_mapping
ADD COLUMN customer_provider_id cts.resource_id;
COMMENT ON COLUMN cts.provider_org_mapping.customer_provider_id IS 'A column for storing the customer-facing IdP ID, which is generated by Confluent. This ID serves as a layer of separation between the customer and internal changes to how IdPs are handled.';

-- Add trigger for populating the customer_provider_id upon creation of a new provider_org_mapping entry
CREATE OR REPLACE FUNCTION cts.copy_internal_provider_id_to_customer_provider_id()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF NEW.customer_provider_id IS NULL THEN
            NEW.customer_provider_id = NEW.provider_id;
        END IF;
        RETURN NEW;
    END $$;

CREATE TRIGGER init_customer_provider_id
    BEFORE INSERT ON cts.provider_org_mapping
    FOR EACH ROW
    EXECUTE FUNCTION cts.copy_internal_provider_id_to_customer_provider_id();