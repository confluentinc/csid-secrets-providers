-- NOTE: This file is no longer a pure dump. Rather, it is manually updated.

--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: deployment; Type: SCHEMA; Schema: -; Owner: caas
--

CREATE USER caas;

CREATE SCHEMA deployment;
CREATE SCHEMA cc_capacity_service;

CREATE DOMAIN cc_capacity_service.k8s_cluster_id AS text NOT NULL;
CREATE DOMAIN cc_capacity_service.cloud_id AS text NOT NULL;
CREATE DOMAIN cc_capacity_service.region_id AS text NOT NULL;
CREATE DOMAIN cc_capacity_service.logical_cluster_id AS text NOT NULL;
CREATE DOMAIN cc_capacity_service.physical_cluster_id AS text NOT NULL;
CREATE DOMAIN cc_capacity_service.network_region_id AS text NOT NULL;
CREATE TYPE cc_capacity_service.cc_resource_type AS ENUM ('REALM', 'NETWORK',
            'KUBERNETES', 'PHYSICAL_CLUSTER');

ALTER SCHEMA deployment OWNER TO caas;
ALTER SCHEMA cc_capacity_service OWNER to caas;

CREATE SCHEMA IF NOT EXISTS auditing;

ALTER SCHEMA auditing OWNER TO caas;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: cloud_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN cloud_id AS character varying(16) NOT NULL;


ALTER DOMAIN cloud_id OWNER TO caas;

--
-- Name: physical_cluster_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN physical_cluster_id AS character varying(32);


ALTER DOMAIN physical_cluster_id OWNER TO caas;


--
-- Name: logical_cluster_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN logical_cluster_id AS character varying(32) NOT NULL;


ALTER DOMAIN logical_cluster_id OWNER TO caas;


--
-- Name: physical_cluster_version; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN physical_cluster_version AS character varying(32) NOT NULL;


ALTER DOMAIN physical_cluster_version OWNER TO caas;

--
-- Name: cp_component_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN cp_component_id AS character varying(32) NOT NULL;


ALTER DOMAIN cp_component_id OWNER TO caas;

--
-- Name: environment_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN environment_id AS character varying(32) NOT NULL;


ALTER DOMAIN environment_id OWNER TO caas;

--
-- Name: hash_function; Type: TYPE; Schema: public; Owner: caas
--

CREATE TYPE hash_function AS ENUM (
    'none',
    'bcrypt'
);


ALTER TYPE hash_function OWNER TO caas;

--
-- Name: k8s_cluster_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN k8s_cluster_id AS character varying(32) NOT NULL;


ALTER DOMAIN k8s_cluster_id OWNER TO caas;

--
-- Name: network_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN network_id AS character varying(32) NOT NULL;


ALTER DOMAIN network_id OWNER TO caas;

--
-- Name: region_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN region_id AS character varying(32) NOT NULL;


ALTER DOMAIN region_id OWNER TO caas;

--
-- Name: stream_governance_region_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN stream_governance_region_id AS text NOT NULL;


ALTER DOMAIN stream_governance_region_id OWNER TO caas;

--
-- Name: sasl_mechanism; Type: TYPE; Schema: public; Owner: caas
--

CREATE TYPE sasl_mechanism AS ENUM (
    'PLAIN',
    'SCRAM-SHA-256',
    'SCRAM-SHA-512'
);


ALTER TYPE sasl_mechanism OWNER TO caas;

--
-- Name: account_id; Type: DOMAIN; Schema: public; Owner: caas
--

CREATE DOMAIN account_id AS character varying(32) NOT NULL;


ALTER DOMAIN account_id OWNER TO caas;

-- Inject capacity schema into mothership database
SET search_path TO DEFAULT ;
-- 
-- K8s_cluster Type: TABLE; Schema: cc_capacity_service; owner: caas
-- 

CREATE TABLE IF NOT EXISTS cc_capacity_service.k8s_cluster (
    id cc_capacity_service.k8s_cluster_id PRIMARY KEY,
    is_schedulable boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone,
    -- this field is meant to be fk, but we can't specify it due to the order of data saved to DB is not guaranteed.
    network_region_id cc_capacity_service.network_region_id, 
    provider jsonb
);



-- physical cluster Type: TABLE; Schema: cc_capacity_service; owner: caas



CREATE TABLE IF NOT EXISTS cc_capacity_service.physical_cluster (
    id cc_capacity_service.physical_cluster_id PRIMARY KEY,
    -- this field is meant to be fk, but we can't specify it due to the order of data saved to DB is not guaranteed.
    k8s_cluster_id cc_capacity_service.k8s_cluster_id,
    type text NOT NULL,
    config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone,
    is_schedulable boolean DEFAULT true NOT NULL,
    sni_enabled boolean DEFAULT false NOT NULL
);

-- 
--  logical cluster info Type: TABLE; Schema: cc_capacity_service; owner: caas
-- 


CREATE TABLE IF NOT EXISTS cc_capacity_service.logical_cluster (
    id cc_capacity_service.logical_cluster_id PRIMARY KEY NOT NULL,
    -- this field is meant to be fk, but we can't specify it due to the order of data saved to DB is not guaranteed.
    physical_cluster_id cc_capacity_service.physical_cluster_id,
    type text NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone
);

-- 
-- traffic info Type: TABLE; Schema: cc_capacity_service; owner: caas
-- 

CREATE TABLE IF NOT EXISTS cc_capacity_service.network_info (
    id integer PRIMARY KEY NOT NULL,
    -- nid is the network region id in k8s_cluster info
    nid cc_capacity_service.network_region_id,
    cloud text NOT NULL,
    region text NOT NULL,
    zone_ids text[],
    desired_state text NOT NULL,
    actual_state text NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    actual_modified timestamp without time zone DEFAULT now() NOT NULL,
    enable_sni boolean DEFAULT true NOT NULL,
    realm text DEFAULT ''::text NOT NULL,
    dedicated boolean DEFAULT true NOT NULL,
    deactivated timestamp without time zone,
    desired_connection_types text[] DEFAULT '{}'::text[] NOT NULL,
    environment_id text Default ''::text NOT NULL
);

CREATE TABLE IF NOT EXISTS cc_capacity_service.constraints (
    resource_id       text NOT NULL,
    cc_resource_type  cc_capacity_service.cc_resource_type NOT NULL,
    -- Valid values for constraint types and custom enforced on request proto vs database to allow
    -- for easier changes.
    constraint_types  text[] DEFAULT array[]::text[],
    constraint_custom jsonb DEFAULT '{}',
    created     timestamp without time zone DEFAULT now() NOT NULL,
    modified    timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone DEFAULT NULL,
    PRIMARY KEY (resource_id, cc_resource_type)
);

CREATE TABLE IF NOT EXISTS cc_capacity_service.region (
    id cc_capacity_service.region_id PRIMARY KEY NOT NULL,
    cloud cc_capacity_service.cloud_id,
    config jsonb,
    byoc_config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    name text NOT NULL
);

CREATE TABLE IF NOT EXISTS cc_capacity_service.zone (
    id text PRIMARY KEY NOT NULL,
    zone_id text NOT NULL,
    name text NOT NULL,
    region_id text NOT NULL,
    sni_enabled boolean DEFAULT true NOT NULL,
    schedulable boolean DEFAULT true NOT NULL,
    realm text NOT NULL,
    schedulable_feature jsonb,
    deactivated timestamp without time zone DEFAULT now() NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS cc_capacity_service.realm (
    id text PRIMARY KEY NOT NULL,
    cloud_id text NOT NULL,
    name text NOT NULL,
    is_schedulable boolean NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);

-- setup indexes and keys

CREATE INDEX IF NOT EXISTS index_k8s_cluster_provider ON cc_capacity_service.k8s_cluster USING gin (provider);
CREATE INDEX IF NOT EXISTS index_k8s_cluster_deactivated ON cc_capacity_service.k8s_cluster USING btree (deactivated);

CREATE INDEX IF NOT EXISTS index_k8s_cluster_network_region_id ON cc_capacity_service.k8s_cluster USING btree (network_region_id);
CREATE INDEX IF NOT EXISTS index_physical_cluster_type ON cc_capacity_service.physical_cluster USING btree (type);
CREATE INDEX IF NOT EXISTS index_physical_cluster_k8s_cluster_id ON cc_capacity_service.physical_cluster USING btree (k8s_cluster_id);
CREATE INDEX IF NOT EXISTS index_physical_cluster_deactivated ON cc_capacity_service.physical_cluster USING btree (deactivated);
CREATE INDEX IF NOT EXISTS index_physical_cluster_config ON cc_capacity_service.physical_cluster USING gin (config);

CREATE INDEX IF NOT EXISTS network_nid ON cc_capacity_service.network_info USING btree (nid);
CREATE INDEX IF NOT EXISTS index_network_info_deactivated ON cc_capacity_service.network_info USING btree (deactivated);

CREATE INDEX IF NOT EXISTS index_logical_cluster_physical_cluster_id ON cc_capacity_service.logical_cluster USING btree (physical_cluster_id);
CREATE INDEX IF NOT EXISTS index_logical_cluster_deactivated ON cc_capacity_service.logical_cluster USING btree (deactivated);
CREATE INDEX IF NOT EXISTS index_logical_cluster_type ON cc_capacity_service.logical_cluster USING btree (type);

CREATE INDEX IF NOT EXISTS index_constraints_constraint_types ON cc_capacity_service.constraints
    USING GIN (constraint_types);
CREATE INDEX IF NOT EXISTS index_constraints_constraint_custom ON cc_capacity_service.constraints
    USING GIN (constraint_custom);
CREATE INDEX IF NOT EXISTS index_constraints_deactivated ON
    cc_capacity_service.constraints(deactivated);
CREATE INDEX IF NOT EXISTS environment_id_idx ON cc_capacity_service.network_info USING btree (environment_id);

CREATE INDEX IF NOT EXISTS index_zone_region_id_idx ON cc_capacity_service.zone USING btree (region_id);
CREATE INDEX IF NOT EXISTS index_zone_schedulable_feature_idx ON cc_capacity_service.zone USING gin (schedulable_feature);
CREATE INDEX IF NOT EXISTS index_zone_schedulable_idx ON cc_capacity_service.zone USING btree (schedulable);

CREATE INDEX IF NOT EXISTS index_region_cloud_id_idx ON cc_capacity_service.region USING btree (cloud);

CREATE INDEX IF NOT EXISTS index_realm_cloud_id_idx ON cc_capacity_service.realm USING btree (cloud_id);
CREATE INDEX IF NOT EXISTS index_realm_schedulale_idx ON cc_capacity_service.realm USING btree (is_schedulable);

SET search_path = deployment, pg_catalog;

--
-- Name: account_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE account_num
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE account_num OWNER TO caas;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE account (
    id public.account_id DEFAULT ('a-'::text || nextval('account_num'::regclass)) NOT NULL,
    name character varying(64) NOT NULL,
    config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated boolean DEFAULT false NOT NULL,
    organization_id integer NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    deactivated_at timestamp without time zone
);


ALTER TABLE account OWNER TO caas;

CREATE UNIQUE INDEX account_name_is_unique ON deployment.account USING btree (name, organization_id) WHERE (deactivated = FALSE);
CREATE INDEX IF NOT EXISTS account_deactivated_at ON deployment.account (deactivated_at);

INSERT INTO account (id, name, organization_id) VALUES ('t0', 'Internal', 0);

--
-- Name: cloud; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE cloud (
    id public.cloud_id NOT NULL,
    config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    name TEXT DEFAULT '' NOT NULL
);


ALTER TABLE cloud OWNER TO caas;

--
-- Name: network_isolation_domain_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE IF NOT EXISTS network_isolation_domain_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;

ALTER TABLE network_isolation_domain_num OWNER TO caas;

--
-- Name: network_isolation_domain; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE IF NOT EXISTS network_isolation_domain (
    id text PRIMARY KEY DEFAULT ('nid-' || nextval('network_isolation_domain_num')::text),
    description varchar(140) NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone DEFAULT NULL
);

ALTER TABLE network_isolation_domain OWNER TO caas;

--
-- Name: deployment_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE IF NOT EXISTS deployment_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;

ALTER TABLE deployment_num OWNER TO caas;

--
-- Name: deployment; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE IF NOT EXISTS deployment (
    id                  text PRIMARY KEY DEFAULT ('deployment-' || nextval('deployment_num')::text),
    created             timestamp without time zone DEFAULT now() NOT NULL,
    modified            timestamp without time zone DEFAULT now() NOT NULL,
    deactivated         timestamp without time zone DEFAULT NULL,
    account_id          varchar(140) NOT NULL,
    network_access      jsonb,
    network_region_id   text NOT NULL,
    sku                 varchar(140) NOT NULL,
    provider            jsonb DEFAULT '{}'::jsonb,
    dedicated           boolean DEFAULT FALSE NOT NULL
);

ALTER TABLE deployment OWNER TO caas;

--
-- Name: physical_cluster_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE physical_cluster_num
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

  ALTER TABLE physical_cluster_num OWNER TO caas;

--
-- Name: physical_cluster_operation_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE physical_cluster_operation_num
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE physical_cluster_operation_num OWNER TO caas;

--
-- Name: physical_cluster; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE physical_cluster (
    id public.physical_cluster_id NOT NULL,
    k8s_cluster_id public.k8s_cluster_id,
    type character varying(32) NOT NULL,
    config jsonb,
    deactivated timestamp without time zone,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    is_schedulable boolean DEFAULT true NOT NULL,
    network_isolation_domain_id text,
    sni_enabled bool DEFAULT false NOT NULL,
    multitenant_oauth_superuser_disabled bool DEFAULT false NOT NULL,
    provider jsonb DEFAULT '{}'::jsonb,
    resource_profile jsonb,
    -- V2 physical cluster API support below -- 
    config_metadata jsonb DEFAULT '{}'::jsonb,
    custom_resource_type text DEFAULT '' not null,
    custom_resource jsonb DEFAULT '{}'::jsonb,
    etag text DEFAULT '' not null,
    operation jsonb DEFAULT '{}'::jsonb
);

ALTER TABLE physical_cluster OWNER TO caas;

ALTER TABLE deployment.physical_cluster ADD CONSTRAINT "fk-physical_cluster-network_isolation_domain" FOREIGN KEY ("network_isolation_domain_id") REFERENCES deployment.network_isolation_domain ("id") NOT VALID;

ALTER TABLE deployment.physical_cluster VALIDATE CONSTRAINT "fk-physical_cluster-network_isolation_domain";

CREATE FUNCTION physical_cluster_updated() RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.modified := now();
  NEW.etag := md5(NEW::text)::text;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_physical_cluster_updated
    BEFORE UPDATE ON physical_cluster
    FOR EACH ROW
    EXECUTE PROCEDURE physical_cluster_updated();

CREATE TRIGGER trigger_physical_cluster_created  -- we want to set the etag on INSERT too. Might as well call this func
    BEFORE INSERT ON physical_cluster
    FOR EACH ROW
    EXECUTE PROCEDURE physical_cluster_updated();


--
-- Name: logical_cluster_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE logical_cluster_num
  START WITH 1
  INCREMENT BY 1
  NO MINVALUE
  NO MAXVALUE
  CACHE 1;

ALTER TABLE logical_cluster_num OWNER TO caas;

--
-- Name: logical_cluster; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE logical_cluster (
    id public.logical_cluster_id NOT NULL,
    name character varying(64) NOT NULL,
    physical_cluster_id public.physical_cluster_id,
    type character varying(32) NOT NULL,
    account_id public.account_id,
    config jsonb,
    deactivated timestamp without time zone,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deployment_id text,
    organization_id integer,
    org_resource_id text,
    region text DEFAULT ''::text NOT NULL,
    cloud text DEFAULT ''::text NOT NULL,
    network_id text DEFAULT ''::text NOT NULL,
    sku text DEFAULT NULL
);

ALTER TABLE logical_cluster OWNER TO caas;

--
-- Name: logical_cluster_status; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE logical_cluster_status (
    id public.logical_cluster_id NOT NULL,
    status_detail jsonb DEFAULT '{}'::jsonb NOT NULL,
    status_modified timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE logical_cluster_status OWNER TO caas;

--
-- Name: cp_component; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE cp_component (
    id public.cp_component_id NOT NULL,
    default_version public.physical_cluster_version DEFAULT '0.0.7'::character varying,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE cp_component OWNER TO caas;

--
-- Name: environment; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE environment (
    id public.environment_id NOT NULL,
    config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE environment OWNER TO caas;

--
-- Name: k8s_cluster_num; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE k8s_cluster_num
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE k8s_cluster_num OWNER TO caas;

--
-- Name: k8s_cluster; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE k8s_cluster (
    id public.k8s_cluster_id DEFAULT ('k8s-'::text || nextval('k8s_cluster_num'::regclass)) NOT NULL,
    config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone,
    network_region_id text,
    provider jsonb DEFAULT '{}'::jsonb,
    status jsonb DEFAULT '{}'::jsonb,
    k8saas_id text
);


ALTER TABLE k8s_cluster OWNER TO caas;

--
-- Name: organization; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE organization (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    deactivated boolean DEFAULT false NOT NULL,
    plan jsonb NOT NULL DEFAULT('{}'),
    sso jsonb NOT NULL DEFAULT('{}'),
    marketplace jsonb NOT NULL DEFAULT('{}'),
    resource_id TEXT NOT NULL,
    audit_log jsonb NOT NULL DEFAULT('{}'),
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated_at timestamp without time zone,
    country_code character varying(2) DEFAULT ''::character varying NOT NULL,
    suspension_status jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_organization_created ON organization (created);
CREATE INDEX IF NOT EXISTS idx_organization_deactivated_at ON organization (deactivated_at);

ALTER TABLE organization
    ADD CONSTRAINT organization_resource_id_uniq UNIQUE (resource_id);

ALTER TABLE organization OWNER TO caas;

COPY organization (id, resource_id, name, plan) FROM stdin;
0	00000000-0000-0000-0000-000000000000	Internal	{"billing": {"email": "caas-team@confluent.io", "method": "MANUAL", "interval": "MONTHLY", "accrued_this_cycle": "0", "stripe_customer_id": ""}, "tax_address": {"zip": "", "city": "", "state": "", "country": "", "street1": "", "street2": ""}, "product_level": "TEAM", "referral_code": ""}
\.


--
-- Name: organization_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE organization_id_seq OWNER TO caas;

--
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE organization_id_seq OWNED BY organization.id;

--
-- Name: physical_cluster_status; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE physical_cluster_status (
    id public.physical_cluster_id NOT NULL,
    status character varying(32) NOT NULL,
    status_detail jsonb DEFAULT '{}'::jsonb NOT NULL,
    status_received timestamp without time zone,
    status_modified timestamp without time zone,
    last_initialized timestamp without time zone,
    last_deleted timestamp without time zone,
    -- Physical Cluster Operation API support
    operation_status jsonb DEFAULT '{}'::jsonb
);

ALTER TABLE physical_cluster_status OWNER TO caas;

CREATE TABLE entitlement (
    id integer NOT NULL,
    external_id character varying(100) NOT NULL,
    name character varying(100) NOT NULL,
    product_id character varying(100) NOT NULL,
    plan_id character varying(100) NOT NULL,
    state character varying(32) NOT NULL,
    external_state character varying(50) NOT NULL,
    usage_reporting_id character varying(100) NOT NULL,
    organization_id integer NOT NULL,
    deactivated boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    started timestamp without time zone,
    ended timestamp without time zone,
    customer_id character varying(100) DEFAULT ''::character varying NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    state_description jsonb DEFAULT '{}'::jsonb,
    offer_type character varying(32),
    parent_id integer,
    subscription_end_time timestamp without time zone,
    CONSTRAINT check_parent_id CHECK ((parent_id <> id))
);

ALTER TABLE entitlement OWNER TO caas;

--
-- Name: entitlement_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE entitlement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE entitlement_id_seq OWNER TO caas;

--
-- Name: entitlement_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE entitlement_id_seq OWNED BY entitlement.id;

--
-- Name: entitlement_external_id_is_unique; Type: INDEX; Schema: deployment; Owner: caas
--

CREATE UNIQUE INDEX entitlement_external_id_is_unique ON entitlement USING btree (external_id) WHERE (deactivated = false);

--
-- Name: entitlement_customer_id; Type: INDEX; Schema: deployment; Owner: -
--

CREATE INDEX entitlement_customer_id ON deployment.entitlement USING btree (customer_id) WHERE (deactivated = false);


--
-- Name: entitlement_organization_id; Type: INDEX; Schema: deployment; Owner: -
--

CREATE INDEX entitlement_organization_id ON deployment.entitlement USING btree (organization_id) WHERE (deactivated = false);

--
-- Name: marketplace_listener_errors; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.marketplace_listener_errors (
    id integer NOT NULL,
    event_id character varying(100) NOT NULL,
    marketplace_partner character varying(36) NOT NULL,
    event_created timestamp without time zone DEFAULT now() NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    error jsonb DEFAULT '{}'::jsonb NOT NULL,
    data_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    entitlement_id integer,
    status character varying(32) NOT NULL DEFAULT 'ERROR'
);

ALTER TABLE deployment.marketplace_listener_errors OWNER TO caas;

--
-- Name: marketplace_listener_errors_id_seq; Type: SEQUENCE; Schema: deployment; Owner: -
--

CREATE SEQUENCE deployment.marketplace_listener_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE deployment.marketplace_listener_errors_id_seq OWNER TO caas;

--
-- Name: marketplace_listener_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: -
--

ALTER SEQUENCE deployment.marketplace_listener_errors_id_seq OWNED BY deployment.marketplace_listener_errors.id;

--
-- Name: marketplace_listener_errors id; Type: DEFAULT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.marketplace_listener_errors ALTER COLUMN id SET DEFAULT nextval('deployment.marketplace_listener_errors_id_seq'::regclass);

--
-- Name: marketplace_listener_errors marketplace_listener_errors_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.marketplace_listener_errors
    ADD CONSTRAINT marketplace_listener_errors_pkey PRIMARY KEY (id);

--
-- Name: conversions; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.conversions
(
    id                                  integer NOT NULL,
    created                             timestamp without time zone DEFAULT now() NOT NULL,
    customer_before_conversion_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    customer_after_conversion_metadata  jsonb DEFAULT '{}'::jsonb NOT NULL,
    conversion_metadata                 jsonb DEFAULT '{}'::jsonb NOT NULL
);

ALTER TABLE deployment.conversions OWNER TO caas;

--
-- Name: conversions_id_seq; Type: SEQUENCE; Schema: deployment; Owner: -
--

CREATE SEQUENCE deployment.conversions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE CACHE 1;

ALTER TABLE deployment.conversions_id_seq OWNER TO caas;

--
-- Name: conversions_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: -
--

ALTER SEQUENCE deployment.conversions_id_seq OWNED BY deployment.conversions.id;

--
-- Name: conversions_id_seq id; Type: DEFAULT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.conversions ALTER COLUMN id SET DEFAULT nextval('deployment.conversions_id_seq'::regclass);

--
-- Name: conversions conversions_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.conversions
    ADD CONSTRAINT conversions_pkey PRIMARY KEY (id);

--
-- Name: marketplace_event; Type: TABLE; Schema: auditing; Owner: -
--
CREATE TABLE IF NOT EXISTS auditing.marketplace_event
(
    event_id VARCHAR (32) PRIMARY KEY,
    event_type VARCHAR (50) NOT NULL,
    marketplace_partner VARCHAR (10) NOT NULL,
    raw_event jsonb NOT NULL,
    created TIMESTAMP NOT NULL
);

CREATE RULE auditing_marketplace_event_delete_protect
    AS ON DELETE TO auditing.marketplace_event
    DO INSTEAD NOTHING;
CREATE RULE auditing_marketplace_event_update_protect
    AS ON UPDATE TO auditing.marketplace_event
    DO INSTEAD NOTHING;
ALTER TABLE auditing.marketplace_event OWNER TO caas;

--
-- Name: marketplace_event; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE IF NOT EXISTS deployment.marketplace_event
(
    id SERIAL PRIMARY KEY,
    event_id VARCHAR (32) NOT NULL,
    event_type VARCHAR (50) NOT NULL,
    marketplace_partner VARCHAR (10) NOT NULL,
    marketplace_integration_type VARCHAR (10),
    organization_id INT,
    customer_id VARCHAR (100),
    entitlement_id INT,
    offer_type VARCHAR (30),
    created TIMESTAMP NOT NULL,
    modified TIMESTAMP NOT NULL,
    event_status VARCHAR (32) NOT NULL,
    event_received_count INT DEFAULT 1,
    poller_retry_count INT DEFAULT 0,
    CONSTRAINT fk_event_id
        FOREIGN KEY(event_id)
            REFERENCES auditing.marketplace_event(event_id)
);

CREATE RULE deployment_marketplace_event_delete_protect
    AS ON DELETE TO deployment.marketplace_event
    DO INSTEAD NOTHING;
ALTER TABLE deployment.marketplace_event OWNER TO caas;

--
-- Name: coupon; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE coupon (
    id TEXT NOT NULL,
    coupon_type INTEGER DEFAULT 0 NOT NULL,
    amount_off INTEGER DEFAULT 0 NOT NULL,
    percent_off INTEGER DEFAULT 0 NOT NULL,
    redeem_by TIMESTAMP WITHOUT TIME zone,
    times_redeemed INTEGER DEFAULT 0 NOT NULL,
    max_redemptions INTEGER DEFAULT 0 NOT NULL,
    duration_in_months INTEGER DEFAULT 0 NOT NULL,
    deactivated BOOL DEFAULT FALSE NOT NULL,
    created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    modified TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL
);

ALTER TABLE coupon OWNER TO caas;

--
-- Name: coupon_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE coupon_id_seq;

ALTER TABLE coupon_id_seq OWNER TO caas;

--
-- Name: coupon_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE coupon_id_seq OWNED BY coupon.id;

--
-- Name: event; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE event (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    resource_type integer,
    resource_id TEXT NOT null,
    action INTEGER NOT NULL,
    data jsonb NOT NULL DEFAULT('{}'),
    created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS event_organization_id_created_idx ON deployment.event (organization_id, created);

ALTER TABLE event OWNER TO caas;

--
-- Name: organization_eventer_state; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE organization_eventer_state (
    last_read_org_id INTEGER
);

ALTER TABLE organization_eventer_state OWNER TO caas;

--
-- Name: region; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE region (
    id public.region_id NOT NULL,
    cloud public.cloud_id,
    config jsonb,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    name TEXT DEFAULT '' NOT NULL,
    byoc_config jsonb
);


ALTER TABLE region OWNER TO caas;

--
-- Name: users; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE users (
    id integer NOT NULL,
    resource_id TEXT NOT NULL,
    email character varying(128) NOT NULL,
    service_name character varying(64) DEFAULT '' NOT NULL,
    service_description character varying(128) DEFAULT '' NOT NULL,
    service_account boolean DEFAULT false NOT NULL,
    first_name character varying(64) NOT NULL,
    last_name character varying(64) NOT NULL,
    deactivated boolean DEFAULT false NOT NULL,
    internal boolean DEFAULT false NOT NULL,
    verified timestamp without time zone DEFAULT timestamp '1970-01-01 00:00:00.00000'  NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    deactivated_at timestamp without time zone,
    social_connection character varying(32) DEFAULT NULL,
    auth_type character varying(32) DEFAULT 'AUTH_TYPE_UNKNOWN' NOT NULL
);

CREATE UNIQUE INDEX users_email_one_active ON deployment.users USING btree (email) WHERE (deactivated = FALSE);
CREATE INDEX IF NOT EXISTS users_deactivated_at ON deployment.users (deactivated_at);

ALTER TABLE users
  ADD CONSTRAINT users_resource_id_uniq UNIQUE (resource_id);

ALTER TABLE users OWNER TO caas;

INSERT INTO users (id, resource_id, email, first_name, last_name, auth_type) VALUES (0, 'u-000000', 'caas-team+internal@confluent.io', '', '', 'AUTH_TYPE_LOCAL');

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO caas;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_resource_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE users_resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_resource_id_seq OWNER TO caas;

CREATE TABLE deployment.org_membership (
    user_resource_id TEXT NOT NULL,
    org_resource_id TEXT NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone DEFAULT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS org_membership_user_and_org_idx ON deployment.org_membership(user_resource_id, org_resource_id) WHERE (deactivated is NULL);

CREATE INDEX IF NOT EXISTS org_membership_user_idx ON deployment.org_membership(user_resource_id) WHERE (deactivated is NULL);

CREATE INDEX IF NOT EXISTS org_membership_org_idx ON deployment.org_membership(org_resource_id) WHERE (deactivated is NULL);

CREATE INDEX IF NOT EXISTS org_membership_deactivated_idx ON deployment.org_membership(deactivated);

INSERT INTO deployment.org_membership (user_resource_id, org_resource_id) VALUES ('u-000000', '00000000-0000-0000-0000-000000000000');

--
-- Name: invitations; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE TABLE deployment.invitations (
    id text PRIMARY KEY,
    org_resource_id TEXT NOT NULL,
    user_resource_id TEXT NOT NULL,
    created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    expiration TIMESTAMP WITHOUT TIME zone NOT NULL,
    last_sent TIMESTAMP WITHOUT TIME zone,
    accepted TIMESTAMP WITHOUT TIME zone,
    deactivated TIMESTAMP WITHOUT TIME zone,
    email TEXT NOT NULL,
    creator_resource_id text DEFAULT ''::text NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS invitations_org_resource_id_idx ON deployment.invitations(org_resource_id);

CREATE INDEX IF NOT EXISTS invitations_user_resource_id_idx ON deployment.invitations(user_resource_id);

CREATE INDEX IF NOT EXISTS invitations_deactivated_idx ON deployment.invitations(deactivated);

ALTER TABLE deployment.invitations OWNER TO caas;

CREATE SEQUENCE deployment.invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE deployment.invitations_id_seq OWNER TO caas;
ALTER SEQUENCE deployment.invitations_id_seq OWNED BY deployment.invitations.id;

CREATE UNIQUE INDEX invitations_user_org_id_unique ON deployment.invitations USING btree (org_resource_id, user_resource_id) WHERE ((deactivated IS NULL) AND (accepted IS NULL));


--
-- Create a DML history TABLE and triggers for CDMUM tables
--

CREATE TABLE deployment.cdmum_dml_history
(
    id SERIAL PRIMARY KEY,
    tstamp timestamp DEFAULT now(),
    schemaname text,
    tabname text,
    operation text,
    who text DEFAULT current_user,
    new_val json,
    old_val json
);
ALTER TABLE deployment.cdmum_dml_history OWNER TO caas;
ALTER TABLE deployment.cdmum_dml_history_id_seq OWNER TO caas;

-- define a DML trigger function
CREATE OR REPLACE FUNCTION cdmum_dml_trigger() RETURNS TRIGGER AS
$$
    BEGIN
        IF TG_OP = 'INSERT'
        THEN
            INSERT INTO deployment.cdmum_dml_history(tabname, schemaname, operation, new_val) VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, row_to_json(NEW));
            RETURN NEW;
        ELSIF TG_OP = 'UPDATE'
        THEN
            INSERT INTO deployment.cdmum_dml_history(tabname, schemaname, operation, new_val, old_val) VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, row_to_json(NEW), row_to_json(OLD));
            RETURN NEW;
        ELSIF TG_OP = 'DELETE'
        THEN
            INSERT INTO deployment.cdmum_dml_history(tabname, schemaname, operation, old_val) VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, row_to_json(OLD));
            RETURN OLD;
        END IF;
    END;
$$ LANGUAGE 'plpgsql';

-- create triggers for CDMUM tables
CREATE TRIGGER t BEFORE INSERT OR UPDATE OR DELETE ON deployment.organization FOR EACH ROW EXECUTE PROCEDURE cdmum_dml_trigger();

--
-- Name: billing_job; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE billing_job (
    id SERIAL PRIMARY KEY,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    month timestamp without time zone DEFAULT now() NOT NULL,
    status jsonb NOT NULL DEFAULT('{}'),
    charges jsonb NOT NULL DEFAULT('{}')
);


ALTER TABLE billing_job OWNER TO caas;

--
-- Name: roll; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE roll (
    id SERIAL PRIMARY KEY,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone DEFAULT NULL,
    status jsonb NOT NULL DEFAULT('{}'),
    request jsonb NOT NULL DEFAULT('{}'),
    clusters jsonb NOT NULL DEFAULT('{}'),
    operation integer NOT NULL DEFAULT 0
);

ALTER TABLE roll OWNER TO caas;

--
-- Name: secret; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE secret (
    id SERIAL PRIMARY KEY,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone DEFAULT NULL,
    type TEXT DEFAULT '' NOT NULL,
    config jsonb DEFAULT '{}' NOT NULL
);

CREATE INDEX secret_logical_clusters_idx ON secret USING gin ((config -> 'api_key' -> 'logical_clusters') jsonb_path_ops);
CREATE INDEX secret_client_logical_clusters_idx ON secret USING gin ((config -> 'api_key' -> 'client_logical_clusters') jsonb_path_ops);
CREATE INDEX secret_api_key_org_resource_index ON secret USING btree ((((config -> 'api_key'::text) ->> 'organization_resource_id'::text)));
CREATE INDEX secret_apikey_key_index ON secret USING btree ((((config -> 'api_key'::text) ->> 'key'::text)));
CREATE INDEX secret_deactivated_idx ON secret USING btree (deactivated);

ALTER TABLE secret OWNER TO caas;

--
-- Name: suspended_resources; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.suspended_resources (
    id integer NOT NULL,
    suspended_resource_id text NOT NULL,
    org_resource_id text NOT NULL,
    deactivated timestamp without time zone,
    created timestamp without time zone DEFAULT now() NOT NULL,
    resource_type character varying(32) NOT NULL
);

--
-- Name: suspended_resources_id_seq; Type: SEQUENCE; Schema: deployment; Owner: -
--

CREATE SEQUENCE deployment.suspended_resources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: suspended_resources_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: -
--

ALTER SEQUENCE deployment.suspended_resources_id_seq OWNED BY deployment.suspended_resources.id;

-- Name: suspended_resources id; Type: DEFAULT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.suspended_resources ALTER COLUMN id SET DEFAULT nextval('deployment.suspended_resources_id_seq'::regclass);

--
-- Name: suspension_resource_id_unique; Type: INDEX; Schema: deployment; Owner: -
--

CREATE UNIQUE INDEX suspension_resource_id_unique ON deployment.suspended_resources USING btree (suspended_resource_id, org_resource_id) WHERE (deactivated IS NULL);

--
-- Name: task; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE task (
    id SERIAL PRIMARY KEY,
    run_date timestamp without time zone DEFAULT now() NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    start_time timestamp without time zone DEFAULT now() NOT NULL,
    end_time timestamp without time zone DEFAULT now() NOT NULL,
    type integer NOT NULL,
    status integer NOT NULL,
    message text DEFAULT('') NOT NULL,
    sub_tasks jsonb NOT NULL DEFAULT('{}')
);

ALTER TABLE task OWNER TO caas;

--
-- Name: usage; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE usage (
    id SERIAL PRIMARY KEY,
    logical_cluster_id public.logical_cluster_id,
    month TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    metrics jsonb NOT NULL DEFAULT('{}'),
    modified TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL
);

ALTER TABLE usage OWNER TO caas;

--
-- Name: promo_code; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE promo_code (
                       id SERIAL PRIMARY KEY,
                       code VARCHAR(50) UNIQUE NOT NULL,
                       amount BIGINT NOT NULL,
                       organization_id INT,
                       code_validity_start_date TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
                       code_validity_end_date TIMESTAMP WITHOUT TIME zone NOT NULL,
                       credit_validity_days INT NOT NULL,
                       max_uses INT NOT NULL DEFAULT (1) CHECK (max_uses > 0),
                       is_enabled BOOLEAN NOT NULL,
                       created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
                       created_by character varying(128) NOT NULL,
                       modified TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
                       modified_by character varying(128) NOT NULL,
                       salesforce_account_id character varying(64),
                       reason character varying(128)
);

CREATE UNIQUE INDEX promo_code_code_index on deployment.promo_code (code);
CREATE INDEX promo_code_created_by_index on deployment.promo_code (created_by);

ALTER TABLE promo_code OWNER TO caas;

--
-- Name: promo_code_claim; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE promo_code_claim (
                            id SERIAL PRIMARY KEY,
                            promo_code_id INT NOT NULL,
                            credit_expiration TIMESTAMP WITHOUT TIME zone NOT NULL,
                            organization_id INT NOT NULL,
                            amount_remaining BIGINT NOT NULL,
                            created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
                            created_by INT NOT NULL,
                            modified TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
                            FOREIGN KEY (promo_code_id) REFERENCES promo_code(id)
);

CREATE INDEX promo_code_claim_organization_id_index on deployment.promo_code_claim (organization_id);
CREATE INDEX promo_code_claim_promo_code_id_index on deployment.promo_code_claim (promo_code_id);
CREATE UNIQUE INDEX promo_code_claim_organization_and_code_index on deployment.promo_code_claim(organization_id, promo_code_id);

ALTER TABLE promo_code_claim OWNER TO caas;

--
-- Name: billing_order; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE billing_order (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    universal_id VARCHAR,
    commit_total BIGINT DEFAULT 0 NOT NULL,
    prepaid_amount BIGINT DEFAULT 0 NOT NULL,
    created_date TIMESTAMP WITHOUT TIME ZONE,
    discount DECIMAL DEFAULT 0 NOT NULL,
    start_date TIMESTAMP WITHOUT TIME ZONE,
    end_date TIMESTAMP WITHOUT TIME ZONE,
    created TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    modified TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    currency VARCHAR(16) NOT NULL,
    status INTEGER,
    billing_cycle INTEGER DEFAULT 0 NOT NULL,
    effective_rate_card_date TIMESTAMP WITHOUT TIME ZONE DEFAULT to_timestamp(0) NOT NULL,
    is_reseller boolean DEFAULT false
);

ALTER TABLE billing_order OWNER TO caas;

--
-- Name: billing_order_organization_id_universal_id_uniq; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY deployment.billing_order ADD CONSTRAINT billing_order_organization_id_universal_id_uniq UNIQUE (organization_id, universal_id);

--
-- Name: api_key; Type: TABLE; Schema: deployment;
--

CREATE TABLE api_key_v2 (
  id SERIAL PRIMARY KEY,
  api_key TEXT UNIQUE NOT NULL  CHECK (api_key<> '') ,
  api_secret TEXT NOT NULL CHECK (api_secret<> ''),
  display_name TEXT,
  description TEXT,
  created TIMESTAMP WITHOUT TIME ZONE DEFAULT current_timestamp NOT NULL,
  modified TIMESTAMP WITHOUT TIME ZONE DEFAULT current_timestamp NOT NULL,
  owner_resource_id TEXT NOT NULL CHECK (owner_resource_id <> ''),
  owner_type TEXT NOT NULL CHECK (owner_type <> ''),
  owner_id INTEGER NOT NULL CHECK (owner_id >= 0),
  resource_id TEXT NOT NULL CHECK (resource_id <> ''),
  resource_type TEXT NOT NULL CHECK (resource_type <> ''),
  organization_resource_id TEXT NOT NULL CHECK (organization_resource_id <> ''),
  physical_kafka_id TEXT NOT NULL CHECK (physical_kafka_id <> ''),
  deleted BOOLEAN DEFAULT false NOT NULL,
  stored_customer_secret BOOLEAN DEFAULT false NOT NULL,
  client_logical_clusters jsonb NOT NULL DEFAULT('[]'),
  target_clusters jsonb NOT NULL DEFAULT('[]'),
  allow_cloud_access BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX api_key_v2_id_idx ON api_key_v2 USING btree (id, deleted);
CREATE INDEX api_key_v2_key_idx ON api_key_v2 USING btree (api_key, deleted);
CREATE INDEX api_key_v2_org_idx ON api_key_v2 USING btree (organization_resource_id, deleted);
CREATE INDEX api_key_v2_org_key_idx ON api_key_v2 USING btree (organization_resource_id, api_key, deleted);
CREATE INDEX api_key_v2_org_owner_idx ON api_key_v2 USING btree (organization_resource_id, owner_resource_id, deleted);
CREATE INDEX api_key_v2_org_resource_idx ON api_key_v2 USING btree (organization_resource_id, resource_id, deleted);
CREATE INDEX api_key_v2_client_logical_clusters_idx ON api_key_v2 USING gin (client_logical_clusters);
CREATE INDEX api_key_v2_target_clusters_idx ON api_key_v2 USING gin (target_clusters jsonb_path_ops);

CREATE FUNCTION api_key_v2_updated() RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.modified := current_timestamp;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_api_key_v2_updated
  BEFORE UPDATE ON api_key_v2
  FOR EACH ROW
  EXECUTE PROCEDURE api_key_v2_updated();

ALTER TABLE api_key_v2 OWNER TO caas;

--
-- Name: api_key_v2_internal_client; Type: TABLE; Schema: deployment; Owner: -
--
CREATE TABLE deployment.api_key_v2_internal_client (
    api_key text NOT NULL,
    client_type text NOT NULL
);

CREATE UNIQUE INDEX api_key_v2_internal_client_api_key_idx ON deployment.api_key_v2_internal_client USING btree (api_key);
CREATE INDEX api_key_v2_internal_client_client_type_idx ON deployment.api_key_v2_internal_client USING btree (client_type);

ALTER TABLE ONLY deployment.api_key_v2_internal_client
    ADD CONSTRAINT api_key_v2_internal_client_api_key_fkey FOREIGN KEY (api_key) REFERENCES deployment.api_key_v2(api_key) ON DELETE CASCADE;

--
-- Name: price; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE price (
    id SERIAL PRIMARY KEY,
    kafka_prices jsonb NOT NULL DEFAULT('{}'),
    connect_prices jsonb NOT NULL DEFAULT('{}'),
    cluster_link_prices jsonb NOT NULL DEFAULT('{}'),
    audit_log_prices jsonb NOT NULL DEFAULT('{}'),
    support_prices jsonb NOT NULL DEFAULT('{}'),
    multipliers jsonb NOT NULL DEFAULT('{}'),
    stream_governance_prices jsonb DEFAULT '{}'::jsonb NOT NULL,
    effective_date TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    modified TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    type INTEGER DEFAULT 1 NOT NULL,
    order_universal_id VARCHAR,
    google_sheet_id VARCHAR,
    source_rate_card_id INTEGER,
    FOREIGN KEY (source_rate_card_id) REFERENCES price(id)
);

ALTER TABLE price OWNER TO caas;

INSERT INTO deployment.price (multipliers, effective_date)
VALUES ('{
  "aws": {
    "eu-west-1": 1,
    "eu-west-2": 1,
    "eu-west-3": 1,
    "sa-east-1": 1,
    "us-east-1": 1,
    "us-east-2": 1,
    "us-west-1": 1,
    "us-west-2": 1,
    "ap-south-1": 1,
    "ca-central-1": 1,
    "eu-central-1": 1,
    "ap-northeast-1": 1,
    "ap-northeast-2": 1,
    "ap-southeast-1": 1,
    "ap-southeast-2": 1
  },
  "gcp": {
    "us-east1": 1,
    "us-east4": 1,
    "us-west1": 1,
    "us-west2": 1,
    "asia-east1": 1,
    "asia-east2": 1,
    "asia-south1": 1,
    "us-central1": 1,
    "europe-west1": 1,
    "europe-west2": 1,
    "europe-west3": 1,
    "europe-west4": 1,
    "europe-north1": 1,
    "asia-northeast1": 1,
    "asia-southeast1": 1,
    "southamerica-east1": 1,
    "australia-southeast1": 1,
    "northamerica-northeast1": 1
  },
  "azure": {
    "eastus": 1,
    "eastus2": 1,
    "uksouth": 1,
    "westus2": 1,
    "centralus": 1,
    "japaneast": 1,
    "westeurope": 1,
    "northeurope": 1,
    "francecentral": 1,
    "southeastasia": 1
  }
}', '2015-02-01 00:00:00');

UPDATE deployment.price SET kafka_prices = '{
  "KafkaPartition": {
    "prices": {
      "aws:high:custom:internet:internet": 0,
      "aws:high:custom:peered-vpc:internet": 0,
      "aws:high:dedicated:internet:internet": 0,
      "aws:high:dedicated:peered-vpc:internet": 0,
      "aws:high:dedicated:private-link:internet": 0,
      "aws:high:dedicated:transit-gateway:internet": 0,
      "aws:high:standard:internet:internet": 0,
      "aws:high:standard_v2:internet:internet": 0.0015,
      "aws:low:basic:internet:internet": 0.004,
      "aws:low:custom:internet:internet": 0,
      "aws:low:custom:peered-vpc:internet": 0,
      "aws:low:dedicated:internet:internet": 0,
      "aws:low:dedicated:peered-vpc:internet": 0,
      "aws:low:dedicated:private-link:internet": 0,
      "aws:low:dedicated:transit-gateway:internet": 0,
      "aws:low:standard:internet:internet": 0,
      "aws:low:standard_v2:internet:internet": 0.0015,
      "azure:high:custom:internet:internet": 0,
      "azure:high:custom:peered-vpc:internet": 0,
      "azure:high:dedicated:internet:internet": 0,
      "azure:high:dedicated:peered-vpc:internet": 0,
      "azure:high:standard:internet:internet": 0,
      "azure:high:standard_v2:internet:internet": 0.0015,
      "azure:low:basic:internet:internet": 0.004,
      "azure:low:custom:internet:internet": 0,
      "azure:low:custom:peered-vpc:internet": 0,
      "azure:low:dedicated:internet:internet": 0,
      "azure:low:dedicated:peered-vpc:internet": 0,
      "azure:low:standard:internet:internet": 0,
      "azure:low:standard_v2:internet:internet": 0.0015,
      "gcp:high:custom:internet:internet": 0,
      "gcp:high:custom:peered-vpc:internet": 0,
      "gcp:high:dedicated:internet:internet": 0,
      "gcp:high:dedicated:peered-vpc:internet": 0,
      "gcp:high:standard:internet:internet": 0,
      "gcp:high:standard_v2:internet:internet": 0.0015,
      "gcp:low:basic:internet:internet": 0.004,
      "gcp:low:custom:internet:internet": 0,
      "gcp:low:custom:peered-vpc:internet": 0,
      "gcp:low:dedicated:internet:internet": 0,
      "gcp:low:dedicated:peered-vpc:internet": 0,
      "gcp:low:standard:internet:internet": 0,
      "gcp:low:standard_v2:internet:internet": 0.0015
    },
    "unit": "Partition-hour"
  },
  "KafkaBase": {
    "prices": {
      "gcp:high:standard:internet:internet": 0,
      "gcp:low:standard:internet:internet": 0,
      "azure:high:dedicated:internet:internet": 0,
      "gcp:low:standard_v2:internet:internet": 1.5,
      "aws:low:basic:internet:internet": 0,
      "aws:low:custom:peered-vpc:internet": 4.0063,
      "aws:low:standard:internet:internet": 0,
      "aws:high:standard_v2:internet:internet": 1.5,
      "azure:low:standard:internet:internet": 0,
      "azure:high:custom:internet:internet": 3.9362,
      "aws:low:dedicated:peered-vpc:internet": 0,
      "azure:high:dedicated:peered-vpc:internet": 0,
      "aws:high:custom:internet:internet": 4.6869,
      "azure:high:standard_v2:internet:internet": 1.5,
      "aws:low:dedicated:private-link:internet": 0,
      "azure:high:standard:internet:internet": 0,
      "gcp:high:dedicated:internet:internet": 0,
      "aws:high:dedicated:private-link:internet": 0,
      "azure:low:custom:internet:internet": 2.7265,
      "aws:high:standard:internet:internet": 0,
      "gcp:low:dedicated:peered-vpc:internet": 0,
      "azure:low:standard_v2:internet:internet": 1.5,
      "gcp:low:custom:internet:internet": 3.2994,
      "gcp:high:custom:internet:internet": 4.7631,
      "aws:high:dedicated:internet:internet": 0,
      "azure:low:dedicated:internet:internet": 0,
      "aws:low:standard_v2:internet:internet": 1.5,
      "azure:low:basic:internet:internet": 0,
      "gcp:low:basic:internet:internet": 0,
      "azure:high:custom:peered-vpc:internet": 4.5502,
      "gcp:high:dedicated:peered-vpc:internet": 0,
      "aws:high:dedicated:peered-vpc:internet": 0,
      "gcp:high:standard_v2:internet:internet": 1.5,
      "azure:low:dedicated:peered-vpc:internet": 0,
      "gcp:low:dedicated:internet:internet": 0,
      "gcp:low:custom:peered-vpc:internet": 4.0438,
      "aws:low:custom:internet:internet": 3.2506,
      "aws:low:dedicated:internet:internet": 0,
      "gcp:high:custom:peered-vpc:internet": 5.5074,
      "aws:high:custom:peered-vpc:internet": 5.4426,
      "aws:high:dedicated:transit-gateway:internet": 0,
      "azure:low:custom:peered-vpc:internet": 3.3405,
      "aws:low:dedicated:transit-gateway:internet": 0
    },
    "unit": "Hour"
  },
  "KSQLNumCSUs": {
    "prices": {
      "gcp:high:standard:internet:internet": 0.2222,
      "gcp:low:standard:internet:internet": 0.2222,
      "azure:high:dedicated:internet:internet": 0.2222,
      "gcp:low:standard_v2:internet:internet": 0.2222,
      "aws:low:basic:internet:internet": 0.2222,
      "aws:low:custom:peered-vpc:internet": 0.2222,
      "aws:low:standard:internet:internet": 0.2222,
      "aws:high:standard_v2:internet:internet": 0.2222,
      "azure:low:standard:internet:internet": 0.2222,
      "azure:high:custom:internet:internet": 0.2222,
      "aws:low:dedicated:peered-vpc:internet": 0.2222,
      "azure:high:dedicated:peered-vpc:internet": 0.2222,
      "aws:high:custom:internet:internet": 0.2222,
      "azure:high:standard_v2:internet:internet": 0.2222,
      "aws:low:dedicated:private-link:internet": 0.2222,
      "azure:high:standard:internet:internet": 0.2222,
      "gcp:high:dedicated:internet:internet": 0.2222,
      "aws:high:dedicated:private-link:internet": 0.2222,
      "azure:low:custom:internet:internet": 0.2222,
      "aws:high:standard:internet:internet": 0.2222,
      "gcp:low:dedicated:peered-vpc:internet": 0.2222,
      "azure:low:standard_v2:internet:internet": 0.2222,
      "gcp:low:custom:internet:internet": 0.2222,
      "gcp:high:custom:internet:internet": 0.2222,
      "aws:high:dedicated:internet:internet": 0.2222,
      "azure:low:dedicated:internet:internet": 0.2222,
      "aws:low:standard_v2:internet:internet": 0.2222,
      "azure:low:basic:internet:internet": 0.2222,
      "gcp:low:basic:internet:internet": 0.2222,
      "azure:high:custom:peered-vpc:internet": 0.2222,
      "gcp:high:dedicated:peered-vpc:internet": 0.2222,
      "aws:high:dedicated:peered-vpc:internet": 0.2222,
      "gcp:high:standard_v2:internet:internet": 0.2222,
      "azure:low:dedicated:peered-vpc:internet": 0.2222,
      "gcp:low:dedicated:internet:internet": 0.2222,
      "gcp:low:custom:peered-vpc:internet": 0.2222,
      "aws:low:custom:internet:internet": 0.2222,
      "aws:low:dedicated:internet:internet": 0.2222,
      "gcp:high:custom:peered-vpc:internet": 0.2222,
      "aws:high:custom:peered-vpc:internet": 0.2222,
      "aws:high:dedicated:transit-gateway:internet": 0.2222,
      "azure:low:custom:peered-vpc:internet": 0.2222,
      "aws:low:dedicated:transit-gateway:internet": 0.2222
    },
    "unit": "CSU-hour"
  },
  "KafkaNetworkRead": {
    "prices": {
      "gcp:high:standard:internet:internet": 0.11,
      "gcp:low:standard:internet:internet": 0.11,
      "azure:high:dedicated:internet:internet": 0.014,
      "gcp:low:standard_v2:internet:internet": 0.04,
      "aws:low:basic:internet:internet": 0.13,
      "aws:low:custom:peered-vpc:internet": 0.0364,
      "aws:low:standard:internet:internet": 0.13,
      "aws:high:standard_v2:internet:internet": 0.06,
      "azure:low:standard:internet:internet": 0.24,
      "azure:high:custom:internet:internet": 0.0227,
      "aws:low:dedicated:peered-vpc:internet": 0.032,
      "azure:high:dedicated:peered-vpc:internet": 0.014,
      "aws:high:custom:internet:internet": 0.0523,
      "azure:high:standard_v2:internet:internet": 0.05,
      "aws:low:dedicated:private-link:internet": 0.032,
      "azure:high:standard:internet:internet": 0.24,
      "gcp:high:dedicated:internet:internet": 0.008,
      "aws:high:dedicated:private-link:internet": 0.032,
      "azure:low:custom:internet:internet": 0.0227,
      "aws:high:standard:internet:internet": 0.13,
      "gcp:low:dedicated:peered-vpc:internet": 0.008,
      "azure:low:standard_v2:internet:internet": 0.05,
      "gcp:low:custom:internet:internet": 0.0091,
      "gcp:high:custom:internet:internet": 0.0091,
      "aws:high:dedicated:internet:internet": 0.046,
      "azure:low:dedicated:internet:internet": 0.014,
      "aws:low:standard_v2:internet:internet": 0.06,
      "azure:low:basic:internet:internet": 0.12,
      "gcp:low:basic:internet:internet": 0.11,
      "azure:high:custom:peered-vpc:internet": 0.0227,
      "gcp:high:dedicated:peered-vpc:internet": 0.008,
      "aws:high:dedicated:peered-vpc:internet": 0.032,
      "gcp:high:standard_v2:internet:internet": 0.04,
      "azure:low:dedicated:peered-vpc:internet": 0.014,
      "gcp:low:dedicated:internet:internet": 0.008,
      "gcp:low:custom:peered-vpc:internet": 0.0091,
      "aws:low:custom:internet:internet": 0.0523,
      "aws:low:dedicated:internet:internet": 0.046,
      "gcp:high:custom:peered-vpc:internet": 0.0091,
      "aws:high:custom:peered-vpc:internet": 0.0364,
      "aws:high:dedicated:transit-gateway:internet": 0.112,
      "azure:low:custom:peered-vpc:internet": 0.0227,
      "aws:low:dedicated:transit-gateway:internet": 0.112
    },
    "unit": "GB"
  },
  "KafkaNumCKUs": {
    "prices": {
      "gcp:high:standard:internet:internet": 0,
      "gcp:low:standard:internet:internet": 0,
      "azure:high:dedicated:internet:internet": 2.941,
      "gcp:low:standard_v2:internet:internet": 0,
      "aws:low:basic:internet:internet": 0,
      "aws:low:custom:peered-vpc:internet": 0.2394,
      "aws:low:standard:internet:internet": 0,
      "aws:high:standard_v2:internet:internet": 0,
      "azure:low:standard:internet:internet": 0,
      "azure:high:custom:internet:internet": 0.3024,
      "aws:low:dedicated:peered-vpc:internet": 3.46,
      "azure:high:dedicated:peered-vpc:internet": 2.941,
      "aws:high:custom:internet:internet": 0.2394,
      "azure:high:standard_v2:internet:internet": 0,
      "aws:low:dedicated:private-link:internet": 3.46,
      "azure:high:standard:internet:internet": 0,
      "gcp:high:dedicated:internet:internet": 2.422,
      "aws:high:dedicated:private-link:internet": 3.46,
      "azure:low:custom:internet:internet": 0.3024,
      "aws:high:standard:internet:internet": 0,
      "gcp:low:dedicated:peered-vpc:internet": 2.422,
      "azure:low:standard_v2:internet:internet": 0,
      "gcp:low:custom:internet:internet": 0.3659,
      "gcp:high:custom:internet:internet": 0.3659,
      "aws:high:dedicated:internet:internet": 3.46,
      "azure:low:dedicated:internet:internet": 2.941,
      "aws:low:standard_v2:internet:internet": 0,
      "azure:low:basic:internet:internet": 0,
      "gcp:low:basic:internet:internet": 0,
      "azure:high:custom:peered-vpc:internet": 0.3024,
      "gcp:high:dedicated:peered-vpc:internet": 2.422,
      "aws:high:dedicated:peered-vpc:internet": 3.46,
      "gcp:high:standard_v2:internet:internet": 0,
      "azure:low:dedicated:peered-vpc:internet": 2.941,
      "gcp:low:dedicated:internet:internet": 2.422,
      "gcp:low:custom:peered-vpc:internet": 0.3659,
      "aws:low:custom:internet:internet": 0.2394,
      "aws:low:dedicated:internet:internet": 3.46,
      "gcp:high:custom:peered-vpc:internet": 0.3659,
      "aws:high:custom:peered-vpc:internet": 0.2394,
      "aws:high:dedicated:transit-gateway:internet": 3.46,
      "azure:low:custom:peered-vpc:internet": 0.3024,
      "aws:low:dedicated:transit-gateway:internet": 3.46
    },
    "unit": "CKU-hour"
  },
  "KafkaStorage": {
    "prices": {
      "gcp:high:standard:internet:internet": 0.00013889,
      "gcp:low:standard:internet:internet": 0.00013889,
      "azure:high:dedicated:internet:internet": 0.00015556,
      "gcp:low:standard_v2:internet:internet": 0.00013889,
      "aws:low:basic:internet:internet": 0.00013889,
      "aws:low:custom:peered-vpc:internet": 0.00015778,
      "aws:low:standard:internet:internet": 0.00013889,
      "aws:high:standard_v2:internet:internet": 0.00013889,
      "azure:low:standard:internet:internet": 0.00013889,
      "azure:high:custom:internet:internet": 0.0002525,
      "aws:low:dedicated:peered-vpc:internet": 0.00013889,
      "azure:high:dedicated:peered-vpc:internet": 0.00015556,
      "aws:high:custom:internet:internet": 0.00015778,
      "azure:high:standard_v2:internet:internet": 0.00013889,
      "aws:low:dedicated:private-link:internet": 0.00013889,
      "azure:high:standard:internet:internet": 0.00013889,
      "gcp:high:dedicated:internet:internet": 0.00012444,
      "aws:high:dedicated:private-link:internet": 0.00013889,
      "azure:low:custom:internet:internet": 0.0002525,
      "aws:high:standard:internet:internet": 0.00013889,
      "gcp:low:dedicated:peered-vpc:internet": 0.00012444,
      "azure:low:standard_v2:internet:internet": 0.00013889,
      "gcp:low:custom:internet:internet": 0.00014139,
      "gcp:high:custom:internet:internet": 0.00014139,
      "aws:high:dedicated:internet:internet": 0.00013889,
      "azure:low:dedicated:internet:internet": 0.00015556,
      "aws:low:standard_v2:internet:internet": 0.00013889,
      "azure:low:basic:internet:internet": 0.00013889,
      "gcp:low:basic:internet:internet": 0.00013889,
      "azure:high:custom:peered-vpc:internet": 0.0002525,
      "gcp:high:dedicated:peered-vpc:internet": 0.00012444,
      "aws:high:dedicated:peered-vpc:internet": 0.00013889,
      "gcp:high:standard_v2:internet:internet": 0.00013889,
      "azure:low:dedicated:peered-vpc:internet": 0.00015556,
      "gcp:low:dedicated:internet:internet": 0.00012444,
      "gcp:low:custom:peered-vpc:internet": 0.00014139,
      "aws:low:custom:internet:internet": 0.00015778,
      "aws:low:dedicated:internet:internet": 0.00013889,
      "gcp:high:custom:peered-vpc:internet": 0.00014139,
      "aws:high:custom:peered-vpc:internet": 0.00015778,
      "aws:high:dedicated:transit-gateway:internet": 0.00013889,
      "azure:low:custom:peered-vpc:internet": 0.0002525,
      "aws:low:dedicated:transit-gateway:internet": 0.00013889
    },
    "unit": "GB-hour"
  },
  "KafkaNetworkWrite": {
    "prices": {
      "gcp:high:standard:internet:internet": 0.22,
      "gcp:low:standard:internet:internet": 0.11,
      "azure:high:dedicated:internet:internet": 0.062,
      "gcp:low:standard_v2:internet:internet": 0.04,
      "aws:low:basic:internet:internet": 0.13,
      "aws:low:custom:peered-vpc:internet": 0.0364,
      "aws:low:standard:internet:internet": 0.13,
      "aws:high:standard_v2:internet:internet": 0.13,
      "azure:low:standard:internet:internet": 0.22,
      "azure:high:custom:internet:internet": 0.2045,
      "aws:low:dedicated:peered-vpc:internet": 0.032,
      "azure:high:dedicated:peered-vpc:internet": 0.062,
      "aws:high:custom:internet:internet": 0.1159,
      "azure:high:standard_v2:internet:internet": 0.12,
      "aws:low:dedicated:private-link:internet": 0.032,
      "azure:high:standard:internet:internet": 0.48,
      "gcp:high:dedicated:internet:internet": 0.034,
      "aws:high:dedicated:private-link:internet": 0.088,
      "azure:low:custom:internet:internet": 0.0227,
      "aws:high:standard:internet:internet": 0.28,
      "gcp:low:dedicated:peered-vpc:internet": 0.01,
      "azure:low:standard_v2:internet:internet": 0.05,
      "gcp:low:custom:internet:internet": 0.0298,
      "gcp:high:custom:internet:internet": 0.0571,
      "aws:high:dedicated:internet:internet": 0.102,
      "azure:low:dedicated:internet:internet": 0.014,
      "aws:low:standard_v2:internet:internet": 0.06,
      "azure:low:basic:internet:internet": 0.12,
      "gcp:low:basic:internet:internet": 0.11,
      "azure:high:custom:peered-vpc:internet": 0.2045,
      "gcp:high:dedicated:peered-vpc:internet": 0.034,
      "aws:high:dedicated:peered-vpc:internet": 0.088,
      "gcp:high:standard_v2:internet:internet": 0.11,
      "azure:low:dedicated:peered-vpc:internet": 0.014,
      "gcp:low:dedicated:internet:internet": 0.01,
      "gcp:low:custom:peered-vpc:internet": 0.0298,
      "aws:low:custom:internet:internet": 0.0523,
      "aws:low:dedicated:internet:internet": 0.046,
      "gcp:high:custom:peered-vpc:internet": 0.0571,
      "aws:high:custom:peered-vpc:internet": 0.1,
      "aws:high:dedicated:transit-gateway:internet": 0.088,
      "azure:low:custom:peered-vpc:internet": 0.0227,
      "aws:low:dedicated:transit-gateway:internet": 0.032
    },
    "unit": "GB"
  }
}';

UPDATE deployment.price SET support_prices = '{
  "support-cloud-basic": {
    "min_price": 0
  },
  "support-cloud-premier": {
    "min_price": 10000,
    "usage_price": [
      {
        "rate": 0.1,
        "max_range": 100000,
        "min_range": 0
      },
      {
        "rate": 0.08,
        "max_range": 500000,
        "min_range": 100000
      },
      {
        "rate": 0.06,
        "max_range": 1000000,
        "min_range": 500000
      },
      {
        "rate": 0.03,
        "max_range": -1,
        "min_range": 1000000
      }
    ]
  },
  "support-cloud-business": {
    "min_price": 1000,
    "usage_price": [
      {
        "rate": 0.1,
        "max_range": 50000,
        "min_range": 0
      },
      {
        "rate": 0.08,
        "max_range": 100000,
        "min_range": 50000
      },
      {
        "rate": 0.06,
        "max_range": 1000000,
        "min_range": 100000
      },
      {
        "rate": 0.03,
        "max_range": -1,
        "min_range": 1000000
      }
    ]
  },
  "support-cloud-developer": {
    "min_price": 29,
    "usage_price": [
      {
        "rate": 0.05,
        "max_range": -1,
        "min_range": 0
      }
    ]
  }
}';

UPDATE deployment.price SET connect_prices = '{
  "ConnectNumRecords": {
    "prices": {
      "aws:dedicated:internet:AzureBlobSink": 0,
      "aws:dedicated:internet:GcsSink": 0,
      "aws:dedicated:internet:S3_SINK": 0,
      "aws:dedicated:peered-vpc:AzureBlobSink": 0,
      "aws:dedicated:peered-vpc:GcsSink": 0,
      "aws:dedicated:peered-vpc:S3_SINK": 0,
      "aws:standard_v2:internet:AzureBlobSink": 0,
      "aws:standard_v2:internet:GcsSink": 0,
      "aws:standard_v2:internet:S3_SINK": 0,
      "aws:standard_v2:peered-vpc:AzureBlobSink": 0,
      "aws:standard_v2:peered-vpc:GcsSink": 0,
      "aws:standard_v2:peered-vpc:S3_SINK": 0,
      "azure:dedicated:internet:AzureBlobSink": 0,
      "azure:dedicated:internet:GcsSink": 0,
      "azure:dedicated:internet:S3_SINK": 0,
      "azure:dedicated:peered-vpc:AzureBlobSink": 0,
      "azure:dedicated:peered-vpc:GcsSink": 0,
      "azure:dedicated:peered-vpc:S3_SINK": 0,
      "azure:standard_v2:internet:AzureBlobSink": 0,
      "azure:standard_v2:internet:GcsSink": 0,
      "azure:standard_v2:internet:S3_SINK": 0,
      "azure:standard_v2:peered-vpc:AzureBlobSink": 0,
      "azure:standard_v2:peered-vpc:GcsSink": 0,
      "azure:standard_v2:peered-vpc:S3_SINK": 0,
      "gcp:dedicated:internet:AzureBlobSink": 0,
      "gcp:dedicated:internet:GcsSink": 0,
      "gcp:dedicated:internet:S3_SINK": 0,
      "gcp:dedicated:peered-vpc:AzureBlobSink": 0,
      "gcp:dedicated:peered-vpc:GcsSink": 0,
      "gcp:dedicated:peered-vpc:S3_SINK": 0,
      "gcp:standard_v2:internet:AzureBlobSink": 0,
      "gcp:standard_v2:internet:GcsSink": 0,
      "gcp:standard_v2:internet:S3_SINK": 0,
      "gcp:standard_v2:peered-vpc:AzureBlobSink": 0,
      "gcp:standard_v2:peered-vpc:GcsSink": 0,
      "gcp:standard_v2:peered-vpc:S3_SINK": 0
    },
    "unit": "Record"
  },
  "ConnectNumTasks": {
    "prices": {
      "aws:dedicated:internet:AzureBlobSink": 0.0347,
      "aws:dedicated:internet:GcsSink": 0.0347,
      "aws:dedicated:internet:S3_SINK": 0.0347,
      "aws:dedicated:peered-vpc:AzureBlobSink": 0.0347,
      "aws:dedicated:peered-vpc:GcsSink": 0.0347,
      "aws:dedicated:peered-vpc:S3_SINK": 0.0347,
      "aws:standard_v2:internet:AzureBlobSink": 0.0347,
      "aws:standard_v2:internet:GcsSink": 0.0347,
      "aws:standard_v2:internet:S3_SINK": 0.0347,
      "aws:standard_v2:peered-vpc:AzureBlobSink": 0.0347,
      "aws:standard_v2:peered-vpc:GcsSink": 0.0347,
      "aws:standard_v2:peered-vpc:S3_SINK": 0.0347,
      "azure:dedicated:internet:AzureBlobSink": 0.0347,
      "azure:dedicated:internet:GcsSink": 0.0347,
      "azure:dedicated:internet:S3_SINK": 0.0347,
      "azure:dedicated:peered-vpc:AzureBlobSink": 0.0347,
      "azure:dedicated:peered-vpc:GcsSink": 0.0347,
      "azure:dedicated:peered-vpc:S3_SINK": 0.0347,
      "azure:standard_v2:internet:AzureBlobSink": 0.0347,
      "azure:standard_v2:internet:GcsSink": 0.0347,
      "azure:standard_v2:internet:S3_SINK": 0.0347,
      "azure:standard_v2:peered-vpc:AzureBlobSink": 0.0347,
      "azure:standard_v2:peered-vpc:GcsSink": 0.0347,
      "azure:standard_v2:peered-vpc:S3_SINK": 0.0347,
      "gcp:dedicated:internet:AzureBlobSink": 0.0347,
      "gcp:dedicated:internet:GcsSink": 0.0347,
      "gcp:dedicated:internet:S3_SINK": 0.0347,
      "gcp:dedicated:peered-vpc:AzureBlobSink": 0.0347,
      "gcp:dedicated:peered-vpc:GcsSink": 0.0347,
      "gcp:dedicated:peered-vpc:S3_SINK": 0.0347,
      "gcp:standard_v2:internet:AzureBlobSink": 0.0347,
      "gcp:standard_v2:internet:GcsSink": 0.0347,
      "gcp:standard_v2:internet:S3_SINK": 0.0347,
      "gcp:standard_v2:peered-vpc:AzureBlobSink": 0.0347,
      "gcp:standard_v2:peered-vpc:GcsSink": 0.0347,
      "gcp:standard_v2:peered-vpc:S3_SINK": 0.0347
    },
    "unit": "Task-hour"
  },
  "ConnectThroughput": {
    "prices": {
      "aws:dedicated:internet:AzureBlobSink": 0.03,
      "aws:dedicated:internet:GcsSink": 0.03,
      "aws:dedicated:internet:S3_SINK": 0.03,
      "aws:dedicated:peered-vpc:AzureBlobSink": 0.03,
      "aws:dedicated:peered-vpc:GcsSink": 0.03,
      "aws:dedicated:peered-vpc:S3_SINK": 0.03,
      "aws:standard_v2:internet:AzureBlobSink": 0.03,
      "aws:standard_v2:internet:GcsSink": 0.03,
      "aws:standard_v2:internet:S3_SINK": 0.03,
      "aws:standard_v2:peered-vpc:AzureBlobSink": 0.03,
      "aws:standard_v2:peered-vpc:GcsSink": 0.03,
      "aws:standard_v2:peered-vpc:S3_SINK": 0.03,
      "azure:dedicated:internet:AzureBlobSink": 0.03,
      "azure:dedicated:internet:GcsSink": 0.03,
      "azure:dedicated:internet:S3_SINK": 0.03,
      "azure:dedicated:peered-vpc:AzureBlobSink": 0.03,
      "azure:dedicated:peered-vpc:GcsSink": 0.03,
      "azure:dedicated:peered-vpc:S3_SINK": 0.03,
      "azure:standard_v2:internet:AzureBlobSink": 0.03,
      "azure:standard_v2:internet:GcsSink": 0.03,
      "azure:standard_v2:internet:S3_SINK": 0.03,
      "azure:standard_v2:peered-vpc:AzureBlobSink": 0.03,
      "azure:standard_v2:peered-vpc:GcsSink": 0.03,
      "azure:standard_v2:peered-vpc:S3_SINK": 0.03,
      "gcp:dedicated:internet:AzureBlobSink": 0.03,
      "gcp:dedicated:internet:GcsSink": 0.03,
      "gcp:dedicated:internet:S3_SINK": 0.03,
      "gcp:dedicated:peered-vpc:AzureBlobSink": 0.03,
      "gcp:dedicated:peered-vpc:GcsSink": 0.03,
      "gcp:dedicated:peered-vpc:S3_SINK": 0.03,
      "gcp:standard_v2:internet:AzureBlobSink": 0.03,
      "gcp:standard_v2:internet:GcsSink": 0.03,
      "gcp:standard_v2:internet:S3_SINK": 0.03,
      "gcp:standard_v2:peered-vpc:AzureBlobSink": 0.03,
      "gcp:standard_v2:peered-vpc:GcsSink": 0.03,
      "gcp:standard_v2:peered-vpc:S3_SINK": 0.03
    },
    "unit": "GB"
  }
}';

UPDATE deployment.price SET stream_governance_prices = '{
  "GovernanceBase": {
    "unit": "Hour",
    "prices": {
      "free:1:max": 0,
      "free:2:min": 0,
      "free:2:rate": 0,
      "paid:1:rate": 1
    }
  },
  "SchemaRegistry": {
    "unit": "Schema-hour",
    "prices": {
      "free:1:max": 1000,
      "free:2:min": 1000,
      "free:2:rate": 0.002,
      "paid:1:rate": 0
    }
  }
}';

--
-- Name: price_audit_log; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE price_audit_log (
    id SERIAL PRIMARY KEY,
    rate_card_id INTEGER NOT NULL REFERENCES price(id),
    field_changed VARCHAR(50) NOT NULL,
    previous_value jsonb,
    current_value jsonb,
    operation INTEGER DEFAULT 0 NOT NULL,
    operation_time TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    username character varying(128)
);

ALTER TABLE price_audit_log OWNER TO caas;

CREATE INDEX index_price_audit_log_rate_card_id ON deployment.price_audit_log (rate_card_id);

--
-- Name: billing_invoice; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE billing_invoice (
    id SERIAL PRIMARY KEY,
    organization_id integer NOT NULL,
    total BIGINT DEFAULT 0 NOT NULL,
    lines jsonb NOT NULL DEFAULT('{}'),
    billing_method INTEGER DEFAULT 0 NOT NULL,
    currency TEXT DEFAULT '' NOT NULL,
    from_date timestamp without time zone,
    to_date timestamp without time zone,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    status INTEGER,
    tags jsonb NOT NULL DEFAULT('[]'),
    stripe_invoice_id TEXT
);

ALTER TABLE billing_invoice OWNER TO caas;

CREATE INDEX index_billing_invoice_organization_id ON deployment.billing_invoice (organization_id);
CREATE INDEX index_billing_invoice_not_sent_billing_method_from_date ON deployment.billing_invoice (billing_method,from_date) WHERE status <> 3;

--
-- Name: invoice; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE invoice (
    id SERIAL PRIMARY KEY,
    organization_id integer NOT NULL,
    total BIGINT DEFAULT 0 NOT NULL,
    lines jsonb NOT NULL DEFAULT('{}'),
    billing_method INTEGER DEFAULT 0 NOT NULL,
    currency TEXT DEFAULT '' NOT NULL,
    from_date timestamp without time zone,
    to_date timestamp without time zone,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    status INTEGER
);

ALTER TABLE invoice OWNER TO caas;

--
-- Name: credit; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE credit (
    id SERIAL PRIMARY KEY,
    name text NOT NULL,
    description text NOT NULL DEFAULT '',
    type INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    active_date TIMESTAMP WITHOUT TIME zone NOT NULL,
    expire_date TIMESTAMP WITHOUT TIME zone NOT NULL,
    created TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    modified TIMESTAMP WITHOUT TIME zone DEFAULT now() NOT NULL,
    deactivated boolean DEFAULT false NOT NULL
);

ALTER TABLE credit OWNER TO caas;

--
-- Name: connect_task_usage_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE connect_task_usage_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE connect_task_usage_seq OWNER TO caas;

--
-- Name: connect_task_usage; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE connect_task_usage (
    id integer NOT NULL PRIMARY KEY,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    tasks_used integer,
    organization_id integer NOT NULL,
    task_limit_config jsonb DEFAULT '{}'::jsonb NOT NULL
);

ALTER TABLE connect_task_usage OWNER TO caas;

--
-- Name: connect_task_usage id; Type: DEFAULT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY connect_task_usage ALTER COLUMN id SET DEFAULT nextval('connect_task_usage_seq'::regclass);

--
-- Name: connect_task_usage organization_id_uniq; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY connect_task_usage
    ADD CONSTRAINT organization_id_uniq UNIQUE (organization_id);

--
-- Name: connect_plugin; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE connect_plugin (
    id serial PRIMARY KEY,
    name character varying(64) UNIQUE NOT NULL,
    clouds text[] NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    pa_date timestamp without time zone,
    plugin jsonb DEFAULT '{}'::jsonb NOT NULL,
    display jsonb DEFAULT '{}'::jsonb NOT NULL,
    validation_parameters jsonb DEFAULT '{}'::jsonb NOT NULL
);

ALTER TABLE connect_plugin OWNER TO caas;
-- For ease of use, we can add connect plugins as GA, which is product_maturity_phase 4 so that we don't need to explicitly bump preview tasks for an org.
-- It's also ok to promote to GA after it's in prod.
INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MicrosoftSqlServerSink', '{"aws","azure","gcp"}', '{"class":"MicrosoftSqlServerSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Microsoft+SQL+Server.svg","product_maturity_phase":4,"display_name":"Microsoft SQL Server Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SalesforceCdcSource', '{"aws","azure","gcp"}', '{"class":"SalesforceCdcSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Salesforce_Logo.png","product_maturity_phase":4,"display_name":"Salesforce CDC Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SalesforceSObjectSink', '{"aws","azure","gcp"}', '{"class":"SalesforceSObjectSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Salesforce_Logo.png","product_maturity_phase":4,"display_name":"Salesforce SObject Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureCognitiveSearchSink', '{"aws","azure","gcp"}', '{"class":"AzureCognitiveSearchSink","type":"sink","version":"1.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/CognitiveSearch.png","product_maturity_phase":4,"display_name":"Azure Cognitive Search Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureBlobSink', '{"aws","azure","gcp"}', '{"class":"AzureBlobSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://www.drupal.org/files/styles/grid-3-2x/public/project-images/azure-storage-blob.png","product_maturity_phase":4,"display_name":"Azure Blob Storage Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MongoDbAtlasSource', '{"aws","azure","gcp"}', '{"class":"MongoDbAtlasSource","type":"source","version":"1.3.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/MongoDB_Logo_FullColorBlack_RGB-4td3yuxzjs.png","product_maturity_phase":4,"display_name":"MongoDB Atlas Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MySqlCdcSource', '{"aws","azure","gcp"}', '{"class":"MySqlCdcSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/CDC.png","product_maturity_phase":4,"display_name":"MySQL CDC Source (Debezium)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('s3-sink-internal', '{"aws","azure","gcp"}', '{"class":"s3-sink-internal","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Amazon-Simple-Storage-Service-S3_light-bg%404x.png","product_maturity_phase":4,"display_name":"S3 Sink (Internal)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('JiraSource', '{"aws","azure","gcp"}', '{"class":"JiraSource","type":"source","version":"1.0.7"}', '{"image_url":"https://www.google.com/url?sa=i&url=https%3A%2F%2Fworldvectorlogo.com%2Flogo%2Fjira-1&psig=AOvVaw2yh5844KEaF7hELTwgmbn8&ust=1633567171653000&source=images&cd=vfe&ved=0CAsQjRxqFwoTCKDR8JrGtPMCFQAAAAAdAAAAABAD","product_maturity_phase":4,"display_name":"Jira Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MqttSource', '{"aws","azure","gcp"}', '{"class":"MqttSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/mqtt.png","product_maturity_phase":4,"display_name":"MQTT Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('KinesisSource', '{"aws","azure","gcp"}', '{"class":"KinesisSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Amazon-Kinesis%404x.png","product_maturity_phase":4,"display_name":"Amazon Kinesis Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('RabbitMQSource', '{"aws","azure","gcp"}', '{"class":"RabbitMQSource","type":"source","version":"0.1.0"}', '{"image_url":"https://www.rabbitmq.com/img/rabbitmq_logo_strap.png","product_maturity_phase":4,"display_name":"RabbitMQ Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('RedshiftSink', '{"aws","azure","gcp"}', '{"class":"RedshiftSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Amazon-Redshift%404x.png","product_maturity_phase":4,"display_name":"Amazon Redshift Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('ElasticsearchSink', '{"aws","azure","gcp"}', '{"class":"ElasticsearchSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/ElasticsearchLogo.jpg","product_maturity_phase":4,"display_name":"Elasticsearch Service"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DynamoDbSink', '{"aws","azure","gcp"}', '{"class":"DynamoDbSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://www.gliffy.com/sites/gliffy/files/image/2020-06/Amazon-DynamoDB_dark-bg.png","product_maturity_phase":4,"display_name":"Amazon DynamoDb Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DatadogMetricsSink', '{"aws","azure","gcp"}', '{"class":"DatadogMetricsSink","type":"sink","version":"1.1.4-rc-1b40b3f"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Datadog_Logo.png","product_maturity_phase":4,"display_name":"Datadog Metrics Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('RedditSource', '{"aws","azure","gcp"}', '{"class":"RedditSource","type":"source","version":"0.1.2"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/reddit.png","product_maturity_phase":4,"display_name":"Reddit Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('ZendeskSource', '{"aws","azure","gcp"}', '{"class":"ZendeskSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/zendesk.png","product_maturity_phase":4,"display_name":"Zendesk Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SolaceSink', '{"aws","azure","gcp"}', '{"class":"SolaceSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/Solace_Logo.png","product_maturity_phase":4,"display_name":"Solace Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('CosmosDbSink', '{"aws","azure","gcp"}', '{"class":"CosmosDbSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://api.hub.confluent.io/api/plugins/microsoftcorporation/kafka-connect-cosmos/versions/1.0.4-beta/assets/microsoft.png","product_maturity_phase":4,"display_name":"Azure Cosmos DB Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DataprocSink', '{"aws","azure","gcp"}', '{"class":"DataprocSink","type":"sink","version":""}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Dataproc.png","product_maturity_phase":4,"display_name":"Google Cloud Dataproc Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DatabricksDeltaLakeSink', '{"aws","azure","gcp"}', '{"class":"DatabricksDeltaLakeSink","type":"sink","version":"1.0.0-SNAPSHOT-preview"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/delta-lake-logo.png","product_maturity_phase":4,"display_name":"Databricks Delta Lake Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SalesforcePlatformEventSource', '{"aws","azure","gcp"}', '{"class":"SalesforcePlatformEventSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Salesforce_Logo.png","product_maturity_phase":4,"display_name":"Salesforce Platform Event Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DatagenSource', '{"aws","azure","gcp"}', '{"class":"DatagenSource","type":"source","version":"0.5.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"Datagen Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SnowflakeSink', '{"aws","azure","gcp"}', '{"class":"SnowflakeSink","type":"sink","version":"1.3.1"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Snowflake+logo.png","product_maturity_phase":4,"display_name":"Snowflake Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureServiceBusSource', '{"aws","azure","gcp"}', '{"class":"AzureServiceBusSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/ServiceBusLogo.png","product_maturity_phase":4,"display_name":"Azure Service Bus Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MqttSink', '{"aws","azure","gcp"}', '{"class":"MqttSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/mqtt.png","product_maturity_phase":4,"display_name":"MQTT Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('RabbitMQSink', '{"aws","azure","gcp"}', '{"class":"RabbitMQSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://www.rabbitmq.com/img/rabbitmq_logo_strap.png","product_maturity_phase":4,"display_name":"RabbitMQ Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('PostgresSource', '{"aws","azure","gcp"}', '{"class":"PostgresSource","type":"source","version":"0.1.0"}', '{"image_url":"https://wiki.postgresql.org/images/9/9a/PostgreSQL_logo.3colors.540x557.png","product_maturity_phase":4,"display_name":"Postgres Source "}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureEventHubsSource', '{"aws","azure","gcp"}', '{"class":"AzureEventHubsSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/EventsHublogo.png","product_maturity_phase":4,"display_name":"Azure Event Hubs Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('OracleCdcSource', '{"aws","azure","gcp"}', '{"class":"OracleCdcSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"Oracle CDC Source (Confluent)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('PagerDutySink', '{"aws","azure","gcp"}', '{"class":"PagerDutySink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/CDC.png","product_maturity_phase":4,"display_name":"PagerDuty Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('OracleDatabaseSink', '{"aws","azure","gcp"}', '{"class":"OracleDatabaseSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/oracle-logo.png","product_maturity_phase":4,"display_name":"Oracle Database Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('BigTableSink', '{"aws","azure","gcp"}', '{"class":"BigTableSink","type":"sink","version":"1.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/Cloud_Bigtable.png","product_maturity_phase":4,"display_name":"Google Cloud BigTable Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MongoDbAtlasSink', '{"aws","azure","gcp"}', '{"class":"MongoDbAtlasSink","type":"sink","version":"1.3.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/MongoDB_Logo_FullColorBlack_RGB-4td3yuxzjs.png","product_maturity_phase":4,"display_name":"MongoDB Atlas Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureFunctionsSink', '{"aws","azure","gcp"}', '{"class":"AzureFunctionsSink","type":"sink","version":"1.0.7"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Azure_Functions_Logo.png","product_maturity_phase":4,"display_name":"Azure Functions Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('IbmMQSource', '{"aws","azure","gcp"}', '{"class":"IbmMQSource","type":"source","version":"0.1.0"}', '{"image_url":"https://www.confluent.io/hub/static/9bdcd07b035b67a28858a528d81e0903/d29e0/ibm-mq.jpg","product_maturity_phase":4,"display_name":"IBM MQ source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('PostgresCdcSource', '{"aws","azure","gcp"}', '{"class":"PostgresCdcSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/CDC.png","product_maturity_phase":4,"display_name":"Postgres CDC Source (Debezium)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SftpSource', '{"aws","azure","gcp"}', '{"class":"SftpSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon-sftp.png","product_maturity_phase":4,"display_name":"SFTP Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('OracleDatabaseSource', '{"aws","azure","gcp"}', '{"class":"OracleDatabaseSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"Oracle Database Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('PostgresSink', '{"aws","azure","gcp"}', '{"class":"PostgresSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/elephant.png","product_maturity_phase":4,"display_name":"Postgres Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureSqlDwSink', '{"aws","azure","gcp"}', '{"class":"AzureSqlDwSink","type":"sink","version":"1.1.0"}', '{"image_url":"https://azure.microsoft.com/svghandler/synapse-analytics?width=600&height=315","product_maturity_phase":4,"display_name":"Azure Synapse Analytics Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('CloudWatchLogsSource', '{"aws","azure","gcp"}', '{"class":"CloudWatchLogsSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/AWS-CloudWatch.png","product_maturity_phase":4,"display_name":"Amazon CloudWatch Logs Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SalesforcePushTopicSource', '{"aws","azure","gcp"}', '{"class":"SalesforcePushTopicSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Salesforce_Logo.png","product_maturity_phase":4,"display_name":"Salesforce PushTopic Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SalesforceBulkApiSource', '{"aws","azure","gcp"}', '{"class":"SalesforceBulkApiSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Salesforce_Logo.png","product_maturity_phase":4,"display_name":"Salesforce BulkApi Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('S3_SINK', '{"aws","azure","gcp"}', '{"class":"S3_SINK","type":"sink","version":""}', '{"image_url":" https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Amazon-Simple-Storage-Service-S3_light-bg%404x.png","product_maturity_phase":4,"display_name":"Amazon S3 Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('LambdaSink', '{"aws","azure","gcp"}', '{"class":"LambdaSink","type":"sink","version":""}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/AWS-Lambda%404x.png","product_maturity_phase":4,"display_name":"AWS Lambda Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('RedisSink', '{"aws","azure","gcp"}', '{"class":"RedisSink","type":"sink","version":"0.0.2.12"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/redis_400x400.png","product_maturity_phase":4,"display_name":"Redis Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DatagenSourceInternal', '{"aws","azure","gcp"}', '{"class":"DatagenSourceInternal","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"Datagen Source (Internal)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SplunkSink', '{"aws","azure","gcp"}', '{"class":"SplunkSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Splunk_Logo.png","product_maturity_phase":4,"display_name":"Splunk Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('GithubSource', '{"aws","azure","gcp"}', '{"class":"GithubSource","type":"source","version":"2.0.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/Github_Logo.png","product_maturity_phase":4,"display_name":"Github Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MySqlSink', '{"aws","azure","gcp"}', '{"class":"MySqlSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://cdn.worldvectorlogo.com/logos/mysql.svg","product_maturity_phase":4,"display_name":"MySQL Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('GoogleCloudFunctionsSink', '{"aws","azure","gcp"}', '{"class":"GoogleCloudFunctionsSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/google-cloud-functions-logo.png","product_maturity_phase":4,"display_name":"Google Cloud Functions Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SchedulerCdcPostgresSource', '{"aws","azure","gcp"}', '{"class":"SchedulerCdcPostgresSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/elephant.png","product_maturity_phase":4,"display_name":"Scheduler CDC Postgres Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SalesforcePlatformEventSink', '{"aws","azure","gcp"}', '{"class":"SalesforcePlatformEventSink","type":"sink","version":"1.9.3"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Salesforce_Logo.png","product_maturity_phase":4,"display_name":"Salesforce Platform Event Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SqsSource', '{"aws","azure","gcp"}', '{"class":"SqsSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/Amazon-SQS.png","product_maturity_phase":4,"display_name":"Amazon SQS Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('ServiceNowSource', '{"aws","azure","gcp"}', '{"class":"ServiceNowSource","type":"source","version":"2.3.1"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/ServiceNow.png","product_maturity_phase":4,"display_name":"ServiceNow Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('AzureDataLakeGen2Sink', '{"aws","azure","gcp"}', '{"class":"AzureDataLakeGen2Sink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Azure-DataLake-icon.png","product_maturity_phase":4,"display_name":"Azure Data Lake Storage Gen2 Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SftpSink', '{"aws","azure","gcp"}', '{"class":"SftpSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3.us-west-2.amazonaws.com/icon-sftp.png","product_maturity_phase":4,"display_name":"SFTP Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('DataScienceBigQuerySink', '{"aws","azure","gcp"}', '{"class":"DataScienceBigQuerySink","type":"sink","version":"1"}', '{"image_url":"https://d1i4a15mxbxib1.cloudfront.net/api/plugins/wepay/kafka-connect-bigquery/versions/1.1.2/assets/BigQuery.png","product_maturity_phase":4,"display_name":"Internal Big Query Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('ServiceNowSink', '{"aws","azure","gcp"}', '{"class":"ServiceNowSink","type":"sink","version":"2.3.1"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/ServiceNow.png","product_maturity_phase":4,"display_name":"ServiceNow Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('PubSubSource', '{"aws","azure","gcp"}', '{"class":"PubSubSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Cloud+PubSub.png","product_maturity_phase":4,"display_name":"Google Cloud Pub/Sub Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('GcsSink', '{"aws","azure","gcp"}', '{"class":"GcsSink","type":"sink","version":"0.2.0"}', '{"image_url":"https://api.hub.confluent.io/api/plugins/confluentinc/kafka-connect-gcs/versions/5.0.3/assets/googlecloud.png","product_maturity_phase":4,"display_name":"Google Cloud Storage Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SpannerSink', '{"aws","azure","gcp"}', '{"class":"SpannerSink","type":"sink","version":"0.1.1"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/GCP-Spanner-Logo.svg.png","product_maturity_phase":4,"display_name":"Google Cloud Spanner Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('S3_SINK_INTERNAL', '{"aws","azure","gcp"}', '{"class":"s3-sink-internal","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/Amazon-Simple-Storage-Service-S3_light-bg%404x.png","product_maturity_phase":4,"display_name":"S3 Sink (Internal)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('HttpSink', '{"aws","azure","gcp"}', '{"class":"HttpSink","type":"sink","version":"1.4.0-rc-dcaf3a0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"HTTP Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('CloudWatchMetricsSink', '{"aws","azure","gcp"}', '{"class":"CloudWatchMetricsSink","type":"sink","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/AWS-CloudWatch.png","product_maturity_phase":4,"display_name":"Amazon CloudWatch Metrics Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('ActiveMQSource', '{"aws","azure","gcp"}', '{"class":"ActiveMQSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/ActiveMQ.png","product_maturity_phase":4,"display_name":"ActiveMQ Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('BigQuerySink', '{"aws","azure","gcp"}', '{"class":"BigQuerySink","type":"sink","version":""}', '{"image_url":"https://d1i4a15mxbxib1.cloudfront.net/api/plugins/wepay/kafka-connect-bigquery/versions/1.1.2/assets/BigQuery.png","product_maturity_phase":4,"display_name":"Google BigQuery Sink"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MySqlSource', '{"aws","azure","gcp"}', '{"class":"MySqlSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"MySQL Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('MicrosoftSqlServerSource', '{"aws","azure","gcp"}', '{"class":"MicrosoftSqlServerSource","type":"source","version":"0.1.0"}', '{"image_url":"https://cdn.worldvectorlogo.com/logos/microsoft-sql-server.svg","product_maturity_phase":4,"display_name":"Microsoft SQL Server Source"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('SqlServerCdcSource', '{"aws","azure","gcp"}', '{"class":"SqlServerCdcSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/CDC.png","product_maturity_phase":4,"display_name":"Microsoft SQL Server CDC Source (Debezium)"}');

INSERT INTO deployment.connect_plugin (name, clouds, plugin, display)
VALUES ('HttpSource', '{"aws","azure","gcp"}', '{"class":"HttpSource","type":"source","version":"0.1.0"}', '{"image_url":"https://ccloud-connector-images.s3-us-west-2.amazonaws.com/icon_Connect.png","product_maturity_phase":4,"display_name":"HTTP Source"}');


--
-- Name: connect_error_message_mappings; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE connect_error_message_mappings (
    id serial PRIMARY KEY,
    error_message varchar NOT NULL,
    user_message varchar NOT NULL,
    connector_type varchar NOT NULL,
    deactivated timestamp without time zone DEFAULT NULL
);

ALTER TABLE connect_error_message_mappings OWNER TO caas;

ALTER TABLE connect_error_message_mappings ADD COLUMN check_ld BOOLEAN DEFAULT FALSE;

--
-- Name: feature_opt_ins; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE feature_opt_ins (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    feature INTEGER NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE feature_opt_ins OWNER TO caas;

--
-- Name: billing_record; Type: TABLE; Schema: deployment; Owner: caas
--
CREATE TABLE deployment.billing_record
(
    id                            text PRIMARY KEY,
    organization_id               integer NOT NULL,
    transaction_id                text,
    logical_cluster_id            text,
    invoice_lines                 jsonb   NOT NULL DEFAULT ('{}'),
    metrics                       jsonb   NOT NULL DEFAULT ('{}'),
    amount                        BIGINT  NOT NULL,
    type                          integer NOT NULL,
    window_size                   integer NOT NULL,
    timestamp                     integer NOT NULL,
    created                       timestamp without time zone DEFAULT now() NOT NULL,
    modified                      timestamp without time zone DEFAULT now() NOT NULL,
    deactivated                   boolean          DEFAULT false NOT NULL,
    billed_rate_card_id           integer REFERENCES deployment.price (id),
    effective_global_rate_card_id integer REFERENCES deployment.price (id)
);

ALTER TABLE billing_record OWNER TO caas;

CREATE INDEX index_billing_records_logical_cluster_id ON deployment.billing_record (logical_cluster_id);
CREATE INDEX index_billing_records_organization_id ON deployment.billing_record (organization_id);
CREATE INDEX index_billing_records_transaction_id ON deployment.billing_record (transaction_id);

--
-- Name: billing_record_unbillable; Type: TABLE; Schema: deployment; Owner: caas
--
CREATE TABLE deployment.billing_record_unbillable
(
    id                            text PRIMARY KEY,
    organization_id               integer NOT NULL,
    transaction_id                text,
    logical_cluster_id            text,
    invoice_lines                 jsonb   NOT NULL DEFAULT ('{}'),
    metrics                       jsonb   NOT NULL DEFAULT ('{}'),
    amount                        BIGINT  NOT NULL,
    type                          integer NOT NULL,
    window_size                   integer NOT NULL,
    timestamp                     integer NOT NULL,
    created                       timestamp without time zone DEFAULT now() NOT NULL,
    modified                      timestamp without time zone DEFAULT now() NOT NULL,
    deactivated                   boolean          DEFAULT false NOT NULL,
    billed_rate_card_id           integer REFERENCES deployment.price (id),
    effective_global_rate_card_id integer REFERENCES deployment.price (id),
    reason                        text
);

ALTER TABLE deployment.billing_record_unbillable OWNER TO caas;

CREATE INDEX index_billing_record_unbillable_logical_cluster_id ON deployment.billing_record_unbillable (logical_cluster_id);
CREATE INDEX index_billing_record_unbillable_organization_id ON deployment.billing_record_unbillable (organization_id);

--
-- Name: organization id; Type: DEFAULT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY organization ALTER COLUMN id SET DEFAULT nextval('organization_id_seq'::regclass);

--
-- Name: entitlement id; Type: DEFAULT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY entitlement ALTER COLUMN id SET DEFAULT nextval('entitlement_id_seq'::regclass);

--
-- Name: users id; Type: DEFAULT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);

--
-- Name: usage_metrics_errors; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.usage_metrics_errors (
    id integer NOT NULL,
    operation_id character varying(40) NOT NULL,
    organization_id integer NOT NULL,
    product_level character varying(20) NOT NULL,
    marketplace_partner character varying(10) NOT NULL,
    lines jsonb DEFAULT '{}'::jsonb NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    created timestamp without time zone NOT NULL,
    modified timestamp without time zone NOT NULL,
    error jsonb DEFAULT '{}'::jsonb NOT NULL,
    sent_to_marketplace boolean NOT NULL,
    version character varying(20) DEFAULT '' NOT NULL
);

--
-- Name: usage_metrics_errors; Type: TABLE; Schema: deployment; Owner: caas
--

ALTER TABLE deployment.usage_metrics_errors OWNER TO caas;

--
-- Name: usage_metrics_errors_id_seq; Type: SEQUENCE; Schema: deployment; Owner: -
--

CREATE SEQUENCE deployment.usage_metrics_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: usage_metrics_errors_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

ALTER TABLE deployment.usage_metrics_errors_id_seq OWNER TO caas;

--
-- Name: usage_metrics_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE deployment.usage_metrics_errors_id_seq OWNED BY deployment.usage_metrics_errors.id;

--
-- Name: usage_metrics_errors id; Type: DEFAULT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.usage_metrics_errors ALTER COLUMN id SET DEFAULT nextval('deployment.usage_metrics_errors_id_seq'::regclass);

--
-- Name: usage_metrics_errors usage_metrics_errors_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.usage_metrics_errors
    ADD CONSTRAINT usage_metrics_errors_pkey PRIMARY KEY (id);

--
-- Name: marketplace_usage_feedback; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.marketplace_usage_feedback (
    id integer NOT NULL,
    version character varying(10) NOT NULL,
    aggregated_billing_record_id character varying(36) NOT NULL,
    billing_record_id character varying(36) NOT NULL,
    organization_id integer NOT NULL,
    entitlement_id integer NOT NULL,
    marketplace_partner character varying(10) NOT NULL,
    original_start_time timestamp without time zone NOT NULL,
    reporting_start_time timestamp without time zone NOT NULL,
    agg_debit_amount integer NOT NULL,
    agg_credit_amount integer NOT NULL,
    debit_amount integer NOT NULL,
    credit_amount integer NOT NULL,
    reported_metrics jsonb NOT NULL,
    result jsonb NOT NULL,
    retry_count integer NOT NULL,
    billing_record jsonb NOT NULL,
    partner_request_payload jsonb NOT NULL,
    start_time_trace jsonb NOT NULL,
    created_date timestamp without time zone NOT NULL,
    created timestamp without time zone NOT NULL,
    modified timestamp without time zone NOT NULL,
    deactivated_at timestamp without time zone,
    source_topic character varying(48) NOT NULL,
    source_partition integer NOT NULL,
    source_offset bigint NOT NULL,
    reconcile_type character varying(30)
);

--
-- Name: marketplace_usage_feedback; Type: TABLE; Schema: deployment; Owner: caas
--

ALTER TABLE deployment.marketplace_usage_feedback OWNER TO caas;

--
-- Name: marketplace_usage_feedback_id_seq; Type: SEQUENCE; Schema: deployment; Owner: -
--

CREATE SEQUENCE deployment.marketplace_usage_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: marketplace_usage_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE deployment.marketplace_usage_feedback_id_seq OWNER TO caas;

ALTER SEQUENCE deployment.marketplace_usage_feedback_id_seq OWNED BY deployment.marketplace_usage_feedback.id;

--
-- Name: marketplace_usage_feedback id; Type: DEFAULT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.marketplace_usage_feedback ALTER COLUMN id SET DEFAULT nextval('deployment.marketplace_usage_feedback_id_seq'::regclass);


--
-- Name: marketplace_usage_feedback marketplace_usage_feedback_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.marketplace_usage_feedback
    ADD CONSTRAINT marketplace_usage_feedback_pkey PRIMARY KEY (billing_record_id, created);

CREATE INDEX usage_feedback_organization_id ON deployment.marketplace_usage_feedback (organization_id);
CREATE INDEX usage_feedback_aggregated_billing_record_id ON deployment.marketplace_usage_feedback USING btree (aggregated_billing_record_id);
CREATE INDEX usage_feedback_billing_record_id ON deployment.marketplace_usage_feedback USING btree (billing_record_id);
CREATE INDEX usage_feedback_result_status ON deployment.marketplace_usage_feedback USING btree (((result ->> 'status'::text)));

CREATE TABLE deployment.marketplace_registration (
    id serial NOT NULL,
    organization_id integer unique NOT NULL,
    partner character varying(10) NOT NULL,
    customer_id character varying(100) NOT NULL DEFAULT '',
    customer_state character varying(100) NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL

);

ALTER TABLE deployment.marketplace_registration OWNER TO caas;
ALTER TABLE deployment.marketplace_registration_id_seq OWNER TO caas;

--
-- Name: ddl_history; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.cps_ddl_history (
    id integer NOT NULL,
    ddl_date timestamp with time zone,
    who text DEFAULT CURRENT_USER,
    ddl_tag text,
    object_name text
);


--
-- Name: ddl_history_id_seq; Type: SEQUENCE; Schema: deployment; Owner: -
--

CREATE SEQUENCE deployment.cps_ddl_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ddl_history_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: -
--

ALTER SEQUENCE deployment.cps_ddl_history_id_seq OWNED BY deployment.cps_ddl_history.id;


--
-- Name: dml_history; Type: TABLE; Schema: deployment; Owner: -
--

CREATE TABLE deployment.cps_dml_history (
    id SERIAL PRIMARY KEY,
    tstamp timestamp without time zone DEFAULT now(),
    schemaname text,
    tabname text,
    operation text,
    who text DEFAULT CURRENT_USER,
    new_val json,
    old_val json,
    app_user text,
    request_id text
);

--
-- Name: ddl_history id; Type: DEFAULT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.cps_ddl_history ALTER COLUMN id SET DEFAULT nextval('deployment.cps_ddl_history_id_seq'::regclass);

--
-- Name: ddl_history ddl_history_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY deployment.cps_ddl_history
    ADD CONSTRAINT ddl_history_pkey PRIMARY KEY (id);


--
-- Name: entitlement; Type: TABLE; Schema: deployment;  Owner: caas
--

ALTER TABLE deployment.cps_dml_history OWNER TO caas;
ALTER TABLE deployment.cps_ddl_history OWNER TO caas;
ALTER TABLE deployment.cps_ddl_history_id_seq OWNER TO caas;

--
-- Name: cps_dml_trigger(); Type: FUNCTION; Schema: public; Owner: cloud-partnerships
--

CREATE FUNCTION cps_dml_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF TG_OP = 'INSERT'
        THEN
            INSERT INTO deployment.cps_dml_history(tabname, schemaname, operation, new_val, app_user, request_id) VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, row_to_json(NEW), COALESCE(current_setting('var.app_user', true), ''), COALESCE(current_setting('var.request_id', true), ''));
            RETURN NEW;
        ELSIF TG_OP = 'UPDATE'
        THEN
            INSERT INTO deployment.cps_dml_history(tabname, schemaname, operation, new_val, old_val, app_user, request_id) VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, row_to_json(NEW), row_to_json(OLD), COALESCE(current_setting('var.app_user', true), ''), COALESCE(current_setting('var.request_id', true), ''));
            RETURN NEW;
        ELSIF TG_OP = 'DELETE'
        THEN
            INSERT INTO deployment.cps_dml_history(tabname, schemaname, operation, old_val, app_user, request_id) VALUES (TG_RELNAME, TG_TABLE_SCHEMA, TG_OP, row_to_json(OLD), COALESCE(current_setting('var.app_user', true), ''), COALESCE(current_setting('var.request_id', true), ''));
            RETURN OLD;
        END IF;
    END;
$$;

--
-- Name: entitlement t; Type: TRIGGER; Schema: deployment; Owner: -
--

CREATE TRIGGER entitlement_dml_trigger BEFORE INSERT OR DELETE OR UPDATE ON deployment.entitlement FOR EACH ROW EXECUTE PROCEDURE cps_dml_trigger();

--
-- Name: marketplace_listener_errors t; Type: TRIGGER; Schema: deployment; Owner: -
--

CREATE TRIGGER marketplace_listener_dml_trigger BEFORE INSERT OR DELETE OR UPDATE ON deployment.marketplace_listener_errors FOR EACH ROW EXECUTE PROCEDURE cps_dml_trigger();


--
-- Name: marketplace_registration t; Type: TRIGGER; Schema: deployment; Owner: -
--

CREATE TRIGGER marketplace_registration_dml_trigger BEFORE INSERT OR DELETE OR UPDATE ON deployment.marketplace_registration FOR EACH ROW EXECUTE PROCEDURE cps_dml_trigger();


--
-- Name: usage_metrics_errors t; Type: TRIGGER; Schema: deployment; Owner: -
--

CREATE TRIGGER usage_metrics_dml_trigger BEFORE INSERT OR DELETE OR UPDATE ON deployment.usage_metrics_errors FOR EACH ROW EXECUTE PROCEDURE cps_dml_trigger();

--
-- Data for Name: account; Type: TABLE DATA; Schema: deployment; Owner: caas
--

COPY account (id, name, config, created, modified, deactivated, organization_id) FROM stdin;
\.

--
-- Data for Name: cp_component; Type: TABLE DATA; Schema: deployment; Owner: caas
--

COPY cp_component (id, default_version, created, modified) FROM stdin;
kafka	0.3.0	2017-06-22 13:50:24.580803	2017-06-22 13:50:24.580803
zookeeper	0.3.0	2017-06-22 13:50:24.580803	2017-06-22 13:50:24.580803
\.


--
-- Data for Name: environment; Type: TABLE DATA; Schema: deployment; Owner: caas
--

COPY environment (id, config, created, modified) FROM stdin;
devel	{}	2017-06-08 23:18:32.009539	2017-08-19 01:23:42.349148
\.

INSERT INTO environment (id, config, created, modified) VALUES ('private', '{}', now(), now());

--
-- Name: k8s_cluster_num; Type: SEQUENCE SET; Schema: deployment; Owner: caas
--

SELECT pg_catalog.setval('k8s_cluster_num', 1, true);

--
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: deployment; Owner: caas
--

SELECT pg_catalog.setval('organization_id_seq', 592, true);

INSERT INTO deployment.cloud (id, config, created, modified, name)
VALUES
    ('aws', '{"glb_dns_domain": "aws.glb.devel.cpdev.cloud", "dns_domain": "aws.devel.cpdev.cloud", "internal_dns_domain": "aws.internal.devel.cpdev.cloud"}', now(), now(), 'Amazon Web Services'),
    ('gcp', '{"glb_dns_domain": "gcp.glb.devel.cpdev.cloud", "dns_domain": "gcp.devel.cpdev.cloud", "internal_dns_domain": "gcp.internal.devel.cpdev.cloud"}', now(), now(), 'Google Cloud Platform'),
    ('azure', '{"glb_dns_domain": "azure.glb.devel.cpdev.cloud", "dns_domain": "azure.devel.cpdev.cloud", "internal_dns_domain": "azure.internal.devel.cpdev.cloud"}', now(), now(), 'Azure');

--
-- Data for Name: region; Type: TABLE DATA; Schema: deployment; Owner: caas
--

COPY region (id, cloud, config, created, modified, name, byoc_config) FROM stdin;
us-west-2	aws	{"docker": {"repo": "037803949979.dkr.ecr.us-west-2.amazonaws.com", "image_prefix": "confluentinc"}}	2017-06-22 13:50:24.567898	2017-06-22 13:50:24.567898	US West (Oregon)	{"docker": {"repo": "188758853379.dkr.ecr.us-west-2.amazonaws.com", "image_prefix": "confluentinc"}}
us-west-1	aws	{"docker": {"repo": "037803949979.dkr.ecr.us-west-2.amazonaws.com", "image_prefix": "confluentinc"}}	2017-06-22 13:50:24.567898	2017-06-22 13:50:24.567898	US West (N. California)	{"docker": {"repo": "188758853379.dkr.ecr.us-west-1.amazonaws.com", "image_prefix": "confluentinc"}}
us-central1	gcp	{"docker": {"repo": "us.gcr.io", "image_prefix": "cc-devel"}}	2017-06-22 13:50:24.567898	2017-06-22 13:50:24.567898	US Central	{}
centralus	azure	{"docker": {"repo": "cclouddevel.azurecr.io", "image_prefix": "confluentinc"}}	2017-06-22 13:50:24.567898	2017-06-22 13:50:24.567898	Central US	{}
eastus2	azure	{"docker": {"repo": "cclouddevel.azurecr.io", "image_prefix": "confluentinc"}}	2017-06-22 13:50:24.567898	2017-06-22 13:50:24.567898	East US 2	{}
\.


--
-- Name: account_num; Type: SEQUENCE SET; Schema: deployment; Owner: caas
--

SELECT pg_catalog.setval('account_num', 589, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: deployment; Owner: caas
--

SELECT pg_catalog.setval('users_id_seq', 2, true);


--
-- Name: cloud cloud_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY cloud
    ADD CONSTRAINT cloud_pkey PRIMARY KEY (id);


--
-- Name: physical_cluster physical_cluster_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY physical_cluster
    ADD CONSTRAINT physical_cluster_pkey PRIMARY KEY (id);

--
-- Name: physical_cluster_status physical_cluster_status_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY physical_cluster_status
    ADD CONSTRAINT physical_cluster_status_pkey PRIMARY KEY (id);


--
-- Name: logical_cluster logical_cluster_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY logical_cluster
    ADD CONSTRAINT logical_cluster_pkey PRIMARY KEY (id);


--
-- Name: logical_cluster_status logical_cluster_status_pkey; Type: CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY logical_cluster_status
    ADD CONSTRAINT logical_cluster_status_pkey PRIMARY KEY (id);


--
-- Name: cp_component cp_component_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY cp_component
    ADD CONSTRAINT cp_component_pkey PRIMARY KEY (id);


--
-- Name: environment environment_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY environment
    ADD CONSTRAINT environment_pkey PRIMARY KEY (id);


--
-- Name: k8s_cluster k8s_cluster_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY k8s_cluster
    ADD CONSTRAINT k8s_cluster_pkey PRIMARY KEY (id);

--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: entitlement entitlement_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY entitlement
    ADD CONSTRAINT entitlement_pkey PRIMARY KEY (id);


--
-- Name: region region_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY region
    ADD CONSTRAINT region_pkey PRIMARY KEY (id);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);

--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: event event_organization_id_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(id);

--
-- Name: event event_user_id_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY event
    ADD CONSTRAINT event_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: logical_cluster logical_cluster_account_id_fkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY logical_cluster
    ADD CONSTRAINT logical_cluster_account_id_fkey FOREIGN KEY (account_id) REFERENCES account(id);

-- Name: logical_cluster logical_cluster_deployment_id_fkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY logical_cluster
    ADD CONSTRAINT logical_cluster_deployment_id_fkey FOREIGN KEY (deployment_id) REFERENCES deployment(id);

-- Name: logical_cluster logical_cluster_organization_id_fkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY logical_cluster
    ADD CONSTRAINT logical_cluster_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(id);

--
-- Name: logical_cluster logical_cluster_physical_cluster_id_fkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY logical_cluster
    ADD CONSTRAINT logical_cluster_physical_cluster_id_fkey FOREIGN KEY (physical_cluster_id) REFERENCES physical_cluster(id);


--
-- Name: logical_cluster_status logical_cluster_status_id_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY logical_cluster_status
    ADD CONSTRAINT logical_cluster_status_id_fkey FOREIGN KEY (id) REFERENCES logical_cluster(id) ON DELETE CASCADE;


--
-- Name: physical_cluster physical_cluster_k8s_cluster_id_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY physical_cluster
    ADD CONSTRAINT physical_cluster_k8s_cluster_id_fkey FOREIGN KEY (k8s_cluster_id) REFERENCES k8s_cluster(id);

--
-- Name: physical_cluster_status physical_cluster_status_id_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: -
--

ALTER TABLE ONLY physical_cluster_status
    ADD CONSTRAINT physical_cluster_status_id_fkey FOREIGN KEY (id) REFERENCES physical_cluster(id) ON DELETE CASCADE;


--
-- Name: region region_cloud_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY region
    ADD CONSTRAINT region_cloud_fkey FOREIGN KEY (cloud) REFERENCES cloud(id);


--
-- Name: account account_organization_id_fkey; Type: FK CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(id);


--
-- Name: connect_task_usage connect_task_usage_organization_id_fkey; Type: CONSTRAINT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY connect_task_usage
    ADD CONSTRAINT connect_task_usage_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organization(id) NOT VALID;

ALTER TABLE connect_task_usage VALIDATE CONSTRAINT "connect_task_usage_organization_id_fkey";

--
-- Name: support_plan_history; Type: TABLE; Schema: deployment; Owner: caas
--

CREATE TABLE support_plan_history (
    id integer NOT NULL,
    organization_id integer NOT NULL,
    plan_sku character varying(128) NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    effective_date timestamp without time zone DEFAULT now() NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    PRIMARY KEY (id)
);

ALTER TABLE support_plan_history OWNER TO caas;

--
-- Name: support_plan_history_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE support_plan_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE support_plan_history_id_seq OWNER TO caas;

ALTER SEQUENCE support_plan_history_id_seq OWNED BY support_plan_history.id;

--
-- Name: support_plan_history id; Type: DEFAULT; Schema: deployment; Owner: caas
--

ALTER TABLE ONLY support_plan_history ALTER COLUMN id SET DEFAULT nextval('support_plan_history_id_seq'::regclass);

--
-- Name: secret_index; Type: TABLE; Schema: deployment; Owner: cass
--

CREATE TABLE secret_physical_cluster_map (
	secret_id integer REFERENCES secret(id) ON DELETE CASCADE,
	physical_cluster_id public.physical_cluster_id REFERENCES physical_cluster(id) ON DELETE CASCADE,
	PRIMARY KEY (secret_id, physical_cluster_id)
);

ALTER TABLE secret_physical_cluster_map OWNER TO caas;

--
-- Name: secret_physical_cluster_map_idx; Type: INDEX; Schema: deployment; Owner: cass
--

CREATE INDEX secret_physical_cluster_map_idx ON secret_physical_cluster_map (physical_cluster_id);


--
-- Name: feature_requests id; Type: DEFAULT; Schema: deployment; Owner: caas
--

CREATE TABLE feature_requests (
    id integer PRIMARY KEY,
    type TEXT DEFAULT '' NOT NULL,
    request TEXT DEFAULT '' NOT NULL,
    organization_id integer NOT NULL,
    user_id integer NOT NUlL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    cloud public.cloud_id,
    region public.region_id
);

ALTER TABLE ONLY feature_requests
    ADD CONSTRAINT feature_requests_organization_id_fkey
    FOREIGN KEY (organization_id)
    REFERENCES organization(id);


ALTER TABLE ONLY feature_requests
    ADD CONSTRAINT feature_requests_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id);

ALTER TABLE feature_requests OWNER TO caas;

--
-- Name: feature_requests_id_seq; Type: SEQUENCE; Schema: deployment; Owner: caas
--

CREATE SEQUENCE feature_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE feature_requests_id_seq OWNER TO caas;

--
-- Name: feature_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: deployment; Owner: caas
--

ALTER SEQUENCE feature_requests_id_seq OWNED BY feature_requests.id;

ALTER TABLE ONLY feature_requests ALTER COLUMN id SET DEFAULT nextval('feature_requests_id_seq'::regclass);


--
-- Name: control_plane; Type: SCHEMA; Schema: -; Owner: caas
--

CREATE SCHEMA control_plane;
ALTER SCHEMA control_plane OWNER TO caas;

--
-- Name: policy; Type: TABLE; Schema: control_plane; Owner: caas
--
CREATE TABLE control_plane.policy (
    id SERIAL PRIMARY KEY,
    policy jsonb DEFAULT '{}'::jsonb
);
ALTER TABLE control_plane.policy OWNER to caas;

--
-- Name: upgrade_request; Type: TABLE; Schema: control_plane; Owner: caas
--
CREATE TABLE control_plane.upgrade_request (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL, -- the id of the user, e.g. employee id
    description text NOT NULL, -- preferably a Jira for audit
    request_created timestamp without time zone DEFAULT now() NOT NULL,
    last_modified timestamp without time zone DEFAULT now() NOT NULL,
    cluster_type character varying(32) NOT NULL, -- cluster type, serialization of ClusterType proto: https://github.com/confluentinc/cc-cluster-upgrader/blob/e419317c7e0b2f6648a10e930a3469cf7bf64c5c/src/main/proto/confluent/fleet/shared/common.proto#L19
    clusters jsonb DEFAULT '{}'::jsonb NOT NULL, -- ids of the clusters to be upgraded, as a json array of strings
    options jsonb DEFAULT '{}'::jsonb, -- workflow configuration, serialization of WorkflowOptions proto: https://github.com/confluentinc/cc-cluster-upgrader/blob/e419317c7e0b2f6648a10e930a3469cf7bf64c5c/src/main/proto/confluent/fleet/shared/workflow.proto#L122
    status text NOT NULL,
    status_detail text,
    operation text DEFAULT 'UPGRADE', -- serialization of OperationTypeEnum: https://github.com/confluentinc/cc-structs/blob/266474b82a1accffcade86de184e9b95eb4658e5/fleet/provider/v1/operation.proto#L23
    policy_id INTEGER, -- deprecated
    FOREIGN KEY (policy_id) references control_plane.policy (id) -- deprecated
);
ALTER TABLE control_plane.upgrade_request OWNER TO caas;

--
-- Name: upgrade_task; Type: TABLE; Schema: control_plane; Owner: caas
--
CREATE TABLE control_plane.upgrade_task (
    cluster_id text NOT NULL, -- id of the resource being acted upon (for example, a physical cluster id, a k8s cluster id, etc)
    update_id text, -- id of the underlying operation (for example, the roll id from Scheduler's Roll Service)
    dedicated_cluster boolean, -- deprecated
    upgrade_id INTEGER NOT NULL,
    cluster_type character varying(32) NOT NULL,
    weight INTEGER, -- used to determine a chunk of similar clusters to upgrade
    upgrade_triggered timestamp without time zone DEFAULT timestamp '1970-01-01 00:00:00.00000'  NOT NULL,
    status text NOT NULL,
    last_modified timestamp without time zone DEFAULT now() NOT NULL,
    expected_version text,
    status_detail text,
    current_version text,
    metadata jsonb DEFAULT '{}'::jsonb, -- serialization of TaskMetadata proto: https://github.com/confluentinc/cc-cluster-upgrader/blob/a288bfc5cf7346cf1967fc08e1b5a323b21a13f3/src/main/proto/confluent/fleet/shared/task.proto#L88
    PRIMARY KEY (upgrade_id, cluster_id),
    FOREIGN KEY (upgrade_id) REFERENCES control_plane.upgrade_request (id)
);
ALTER TABLE control_plane.upgrade_task OWNER TO caas;

--
-- Name: skip_upgrade_rules; Type: TABLE; Schema: control_plane; Owner: caas
--
-- List of cluster ids that need to be skipped because they are
-- priority/sensitive customers or we do not want upgrades for them
CREATE TABLE control_plane.skip_upgrade_rules (
    id SERIAL PRIMARY KEY,
    cluster_id text NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    activated timestamp without time zone DEFAULT now()  NOT NULL,
    deactivated timestamp without time zone DEFAULT '2035-12-31 00:00:00',
    description text,
    cluster_type VARCHAR(32) -- TODO: Set to NOT NULL once backfill is done
);
ALTER TABLE control_plane.skip_upgrade_rules OWNER TO caas;

--
-- Name: rollout_phase_execution; Type: TABLE; Schema: control_plane; Owner: caas
--

CREATE TABLE control_plane.rollout_phase_execution (
  instance_type VARCHAR(100),
  operation VARCHAR(100),
  id VARCHAR,
  phase_name VARCHAR(100),
  state VARCHAR(100) NOT NULL,
  rollout_phase_execution_fields jsonb DEFAULT '{}'::jsonb,
  upgrader_request_id INTEGER,
  summary jsonb DEFAULT '{}'::jsonb,
  update_time_millis bigint NOT NULL,
  PRIMARY KEY (instance_type, operation, id, phase_name)
);
ALTER TABLE control_plane.rollout_phase_execution OWNER TO caas;

--
-- Name: rollout; Type: TABLE; Schema: control_plane; Owner: caas
--

CREATE TABLE control_plane.rollout (
  instance_type VARCHAR(100),
  operation VARCHAR(100),
  id VARCHAR,
  state VARCHAR(100) NOT NULL,
  rollout_fields jsonb DEFAULT '{}'::jsonb,
  original_rollout_plan_id VARCHAR,
  actual_rollout_plan jsonb DEFAULT '{}'::jsonb,
  rollout_execution jsonb DEFAULT '{}'::jsonb,
  plan_update_time_millis bigint NOT NULL,
  execution_update_time_millis bigint NOT NULL,
  PRIMARY KEY (instance_type, operation, id)
);
ALTER TABLE control_plane.rollout OWNER TO caas;

--
-- Name: rollout_plan; Type: TABLE; Schema: control_plane; Owner: caas
--

CREATE TABLE control_plane.rollout_plan (
  instance_type VARCHAR(100),
  operation VARCHAR(100),
  id VARCHAR,
  rollout_plan_fields jsonb DEFAULT '{}'::jsonb,
  rollout_phases jsonb DEFAULT '{}'::jsonb,
  update_time_millis bigint NOT NULL,
  PRIMARY KEY (instance_type, operation, id)
);
ALTER TABLE control_plane.rollout_plan OWNER TO caas;

--
-- Name: operation_type; Type: TABLE; Schema: control_plane; Owner: caas
--

CREATE TABLE control_plane.operation_type (
  instance_type VARCHAR(100),
  operation VARCHAR(100),
  operation_type_fields jsonb DEFAULT '{}'::jsonb,
  update_time_millis bigint NOT NULL,
  PRIMARY KEY (instance_type, operation)
);
ALTER TABLE control_plane.operation_type OWNER TO caas;

--
-- Name: kafka; Type: SCHEMA; Schema: -; Owner: caas
--

CREATE SCHEMA kafka;
ALTER SCHEMA kafka OWNER TO caas;

--
-- Name: rollout_plans; Type: TABLE; Schema: kafka; Owner: caas
--

CREATE TABLE kafka.rollout_plans (
    plan_id VARCHAR(100) PRIMARY KEY,
    rollout_request TEXT NOT NULL,
    rollout_requestor TEXT NOT NULL,
    business_justification TEXT NOT NULL,
    skipped_clusters TEXT,
    plan_state VARCHAR(20) NOT NULL,
    plan_notes TEXT NOT NULL,
    rollout_summary TEXT,
    created_by VARCHAR(50) NOT NULL,
    created_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(50) NOT NULL,
    updated_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);
ALTER TABLE kafka.rollout_plans OWNER TO caas;

--
-- Name: rollout_phases; Type: TABLE; Schema: kafka; Owner: caas
--

CREATE TABLE kafka.rollout_phases (
    phase_id VARCHAR(100),
    plan_id VARCHAR(100),
    phase_state VARCHAR(20) NOT NULL,
    phase_notes TEXT NOT NULL,
    current_workflow_id VARCHAR(100),
    current_workflow_status VARCHAR(100) NOT NULL,
    workflow_attempts TEXT NOT NULL,
    start_time TIMESTAMP WITHOUT TIME ZONE,
    end_time TIMESTAMP WITHOUT TIME ZONE,
    created_by VARCHAR(50) NOT NULL,
    created_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(50) NOT NULL,
    updated_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    PRIMARY KEY(phase_id, plan_id)
);
ALTER TABLE kafka.rollout_phases OWNER TO caas;
CREATE INDEX IF NOT EXISTS idx_rollout_phases_plan_id ON kafka.rollout_phases (plan_id);

--
-- Name: rollout_clusters; Type: TABLE; Schema: kafka; Owner: caas
--

CREATE TABLE kafka.rollout_clusters (
    cluster_id VARCHAR(100) REFERENCES deployment.physical_cluster (id),
    phase_id VARCHAR(100),
    plan_id VARCHAR(100),
    cluster_notes TEXT NOT NULL DEFAULT '[]',
    workflow_id VARCHAR(100),
    workflow_cluster_status VARCHAR(100) NOT NULL,
    workflow_cluster_details TEXT,
    spec_kafka_version_before VARCHAR(100),
    spec_kafka_version_after VARCHAR(100),
    psc_version_before VARCHAR(100),
    psc_version_after VARCHAR(100),
    kafka_version_before VARCHAR(100),
    kafka_version_after VARCHAR(100),
    scheduler_id VARCHAR(100),
    roll_progress TEXT,
    start_time TIMESTAMP WITHOUT TIME ZONE,
    end_time TIMESTAMP WITHOUT TIME ZONE,
    created_by VARCHAR(50) NOT NULL,
    created_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(50) NOT NULL,
    updated_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    PRIMARY KEY(cluster_id, phase_id, plan_id)
);
ALTER TABLE kafka.rollout_clusters OWNER TO caas;
CREATE INDEX IF NOT EXISTS idx_rollout_clusters_phase_id ON kafka.rollout_clusters (phase_id);
CREATE INDEX IF NOT EXISTS idx_rollout_clusters_plan_id ON kafka.rollout_clusters (plan_id);

--
-- Name: rollout_heuristics; Type: TABLE; Schema: kafka; Owner: caas
--

CREATE TABLE kafka.rollout_heuristics (
    cluster_id VARCHAR(100) REFERENCES deployment.physical_cluster (id),
    phase_id VARCHAR(100),
    plan_id VARCHAR(100),
    cloud VARCHAR(100),
    region VARCHAR(100),
    zones TEXT,
    is_enterprise_cluster BOOL,
    is_sensitive_cluster BOOL,
    is_multi_zone_cluster BOOL,
    num_pods NUMERIC,
    partition_count NUMERIC,
    received_bytes NUMERIC,
    sent_bytes NUMERIC,
    risk_score NUMERIC,
    created_by VARCHAR(50) NOT NULL,
    created_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(50) NOT NULL,
    updated_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    PRIMARY KEY(cluster_id, plan_id)
);
ALTER TABLE kafka.rollout_heuristics OWNER TO caas;
CREATE INDEX IF NOT EXISTS idx_rollout_heuristics_plan_id ON kafka.rollout_heuristics (plan_id);

--
-- Name: rollout_windows; Type: TABLE; Schema: kafka; Owner: caas
--

CREATE TABLE kafka.rollout_windows (
    window_id VARCHAR(100) PRIMARY KEY,
    cluster_id VARCHAR(100) REFERENCES deployment.physical_cluster (id),
    org_id VARCHAR(100),
    org_res_id VARCHAR(100),
    start_time TIMESTAMP WITHOUT TIME ZONE,
    end_time TIMESTAMP WITHOUT TIME ZONE,
    repeat_interval INT DEFAULT 0,
    window_notes TEXT,
    created_by VARCHAR(50) NOT NULL,
    created_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    updated_by VARCHAR(50) NOT NULL,
    updated_time TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);
ALTER TABLE kafka.rollout_windows OWNER TO caas;
CREATE INDEX IF NOT EXISTS idx_rollout_windows_cluster_id ON kafka.rollout_windows (cluster_id);

--
-- Storage Class
--

CREATE SEQUENCE IF NOT EXISTS deployment.storage_class_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE deployment.storage_class_num OWNER TO caas;

CREATE TABLE IF NOT EXISTS deployment.storage_class (
      id              text PRIMARY KEY DEFAULT ('sc-' || nextval('deployment.storage_class_num')::text),
      encryption_key_id TEXT,
      disk_encryption_set_id TEXT,
      physical_cluster_id TEXT REFERENCES deployment.physical_cluster(id) ON DELETE CASCADE NOT NULL,
      account_id TEXT references deployment.account(id) NOT NULL,
      created timestamp without time zone DEFAULT now() NOT NULL,
      deactivated timestamp without time zone DEFAULT NULL
);

ALTER TABLE deployment.storage_class OWNER TO caas;
CREATE INDEX CONCURRENTLY IF NOT EXISTS storage_class_account_id_idx ON deployment.storage_class (account_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS storage_class_physical_cluster_id_idx ON deployment.storage_class (physical_cluster_id);

--
-- Cloud Service Accounts.
--

CREATE TABLE IF NOT EXISTS deployment.cloud_service_account (
      id TEXT PRIMARY KEY,
      cloud_id TEXT references deployment.cloud(id) NOT NULL
);

ALTER TABLE deployment.cloud_service_account OWNER TO caas;
CREATE INDEX CONCURRENTLY IF NOT EXISTS cloud_service_account_cloud_id_idx ON deployment.cloud_service_account (cloud_id);

--
-- NetworkRegion
--

CREATE SEQUENCE IF NOT EXISTS deployment.network_region_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE deployment.network_region_num OWNER TO caas;

CREATE TABLE IF NOT EXISTS deployment.network_region (
    id              text PRIMARY KEY DEFAULT ('nr-' || nextval('deployment.network_region_num')::text),
    name            text DEFAULT NULL,
    description     text DEFAULT NULL,
    requested_cidr  cidr NOT NULL,
    provider        jsonb NOT NULL DEFAULT '{}'::jsonb,
    account_id      text NOT NULL,
    service_network jsonb DEFAULT '{}'::jsonb,
    site_name       text DEFAULT NULL,
    status          jsonb DEFAULT '{}'::jsonb,
    sni_enabled     boolean NOT NULL,
    region_id       text NOT NULL,
    created         timestamp without time zone DEFAULT now() NOT NULL,
    modified        timestamp without time zone DEFAULT now() NOT NULL,
    deactivated     timestamp without time zone DEFAULT NULL,
    dedicated       boolean DEFAULT True,
    num_zones       integer,
    supported_types text[]
);
ALTER TABLE deployment.network_region OWNER TO caas;

ALTER TABLE ONLY deployment.network_region ADD CONSTRAINT network_region_account_id_fkey FOREIGN KEY (account_id) REFERENCES deployment.account(id) NOT VALID;
ALTER TABLE ONLY deployment.network_region VALIDATE CONSTRAINT network_region_account_id_fkey;

ALTER TABLE ONLY deployment.network_region ADD CONSTRAINT network_region_region_id_fkey FOREIGN KEY (region_id) REFERENCES deployment.region(id) NOT VALID;
ALTER TABLE ONLY deployment.network_region VALIDATE CONSTRAINT network_region_region_id_fkey;

CREATE INDEX CONCURRENTLY IF NOT EXISTS network_region_account_id_idx ON deployment.network_region (account_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS network_region_region_id_idx ON deployment.network_region (region_id);

--
-- NetworkConfig
--

CREATE SEQUENCE IF NOT EXISTS deployment.network_config_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE deployment.network_config_num OWNER TO caas;

CREATE TABLE IF NOT EXISTS deployment.network_config (
    id                  text PRIMARY KEY DEFAULT ('nc-' || nextval('deployment.network_config_num')::text),
    network_region_id   text NOT NULL,
    account_id          text NOT NULL,
    status              jsonb NOT NULL DEFAULT '{}'::jsonb,
    type                text NOT NULL,
    config              jsonb DEFAULT '{}'::jsonb,
    created             timestamp without time zone DEFAULT now() NOT NULL,
    modified            timestamp without time zone DEFAULT now() NOT NULL,
    deactivated         timestamp without time zone DEFAULT NULL,
    shared              boolean DEFAULT False,
    name                text
);
ALTER TABLE deployment.network_config OWNER TO caas;

ALTER TABLE ONLY deployment.network_config ADD CONSTRAINT network_config_network_region_id_fkey FOREIGN KEY (network_region_id) REFERENCES deployment.network_region(id) NOT VALID;
ALTER TABLE ONLY deployment.network_config VALIDATE CONSTRAINT network_config_network_region_id_fkey;

ALTER TABLE ONLY deployment.network_config ADD CONSTRAINT network_config_account_id_fkey FOREIGN KEY (account_id) REFERENCES deployment.account(id) NOT VALID;
ALTER TABLE ONLY deployment.network_config VALIDATE CONSTRAINT network_config_account_id_fkey;

CREATE INDEX CONCURRENTLY IF NOT EXISTS network_config_account_id_idx ON deployment.network_config (account_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS network_config_network_region_id_idx ON deployment.network_config (network_region_id);
--
-- K8sCluster
--

ALTER TABLE deployment.k8s_cluster ADD CONSTRAINT unique_k8saas_id UNIQUE (k8saas_id);

--
-- Zone
--

CREATE SEQUENCE IF NOT EXISTS deployment.zone_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE deployment.zone_num OWNER TO caas;

CREATE TABLE IF NOT EXISTS deployment.zone (
    id                  text PRIMARY KEY DEFAULT ('zone-' || nextval('deployment.zone_num')::text),
    zone_id             text NOT NULL,
    name                text NOT NULL,
    region_id           text NOT NULL,
    sni_enabled         boolean DEFAULT true NOT NULL,
    schedulable         boolean DEFAULT true NOT NULL,
    created             timestamp without time zone DEFAULT now() NOT NULL,
    modified            timestamp without time zone DEFAULT now() NOT NULL,
    deactivated         timestamp without time zone DEFAULT NULL,
    realm               text DEFAULT ''::text NOT NULL,
    schedulable_feature jsonb DEFAULT '{}' NOT NULL
);
ALTER TABLE deployment.zone OWNER TO caas;

ALTER TABLE ONLY deployment.zone ADD CONSTRAINT zone_region_id_fkey FOREIGN KEY (region_id) REFERENCES deployment.region(id) NOT VALID;
ALTER TABLE ONLY deployment.zone VALIDATE CONSTRAINT zone_region_id_fkey;
ALTER TABLE ONLY deployment.zone ADD CONSTRAINT unique_realm_region_id_zone_id UNIQUE (realm, region_id, zone_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS zone_region_id_idx ON deployment.zone (region_id);

INSERT INTO deployment.zone (id, zone_id, name, region_id, sni_enabled, schedulable, created, modified, realm)
VALUES
    -- aws
    ('zone-1', 'usw2-az1', 'us-west-2a', 'us-west-2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '123'),
    ('zone-2', 'usw2-az2', 'us-west-2b', 'us-west-2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '123'),
    ('zone-3', 'usw2-az3', 'us-west-2c', 'us-west-2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '123'),
    ('zone-4', 'usw1-az1', 'us-west-1a', 'us-west-1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '123'),
    ('zone-5', 'usw1-az2', 'us-west-1b', 'us-west-1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '123'),
    ('zone-6', 'usw1-az3', 'us-west-1c', 'us-west-1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '123'),
    -- gcp
    ('zone-7', 'us-central1-b', 'us-central1-b', 'us-central1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-19', 'us-central1-a', 'us-central1-a', 'us-central1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-20', 'us-central1-c', 'us-central1-c', 'us-central1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-21', 'us-central1-f', 'us-central1-f', 'us-central1', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    -- azure
    ('zone-8', 'centralus', 'centralus', 'centralus', false, false, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-9', 'eastus2', 'eastus2', 'eastus2', false, false, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-10', '1', 'centralus-1', 'centralus', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-11', '2', 'centralus-2', 'centralus', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-12', '3', 'centralus-3', 'centralus', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-13', '1', 'eastus2-3', 'eastus2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-14', '2', 'eastus2-3', 'eastus2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    ('zone-15', '3', 'eastus2-3', 'eastus2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', ''),
    -- aws 2
    ('zone-16', 'usw2-az2', 'us-west-2a', 'us-west-2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '321'),
    ('zone-17', 'usw2-az3', 'us-west-2b', 'us-west-2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '321'),
    ('zone-18', 'usw2-az4', 'us-west-2c', 'us-west-2', true, true, '2020-01-01 00:00:00', '2020-01-01 00:00:00', '321');


--
-- Realm
--

CREATE TABLE IF NOT EXISTS deployment.realm (
    id              text NOT NULL PRIMARY KEY,
    cloud_id        text NOT NULL,
    name            text NOT NULL,
    is_schedulable  boolean NOT NULL,
    created         timestamp without time zone DEFAULT now() NOT NULL,
    modified        timestamp without time zone DEFAULT now() NOT NULL
);
ALTER TABLE deployment.realm OWNER TO caas;

ALTER TABLE ONLY deployment.realm ADD CONSTRAINT realm_cloud_id_fkey FOREIGN KEY (cloud_id) REFERENCES deployment.cloud(id) NOT VALID;
ALTER TABLE ONLY deployment.realm VALIDATE CONSTRAINT realm_cloud_id_fkey;

INSERT INTO deployment.realm (id, cloud_id, name, is_schedulable, created, modified)
VALUES
    -- aws
    ('123', 'aws', 'cc-production-1', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-2', 'aws', 'cc-production-2', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('321', 'aws', 'cc-production-3', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-4', 'aws', 'cc-production-4', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-5', 'aws', 'cc-production-5', false, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    -- gcp
    ('realm-6', 'gcp', 'cc-prod-1', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-7', 'gcp', 'cc-prod-2', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-8', 'gcp', 'cc-prod-3', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-9', 'gcp', 'cc-prod-4', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-10', 'gcp', 'cc-prod-5', false, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    -- azure
    ('realm-11', 'azure', 'cc-prod-1', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-12', 'azure', 'cc-prod-2', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-13', 'azure', 'cc-prod-3', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-14', 'azure', 'cc-prod-4', true, '2020-01-01 00:00:00', '2020-01-01 00:00:00'),
    ('realm-15', 'azure', 'cc-prod-5', false, '2020-01-01 00:00:00', '2020-01-01 00:00:00');


INSERT INTO deployment.network_region (id, requested_cidr, region_id, provider, account_id, service_network, status, sni_enabled, created, dedicated)
VALUES
    ('nr-1', '10.0.0.0/16', 'us-west-2', '{"cloud": "aws", "region": "us-west-2", "zones": [{"name": "us-west-2a", "zone_id": "usw2-az1"}, {"name": "us-west-2b", "zone_id": "usw2-az2"}, {"name": "us-west-2c", "zone_id": "usw2-az3"}]}', 't0', '{"aws": {"account_id": "037803949979", "vpc_id": "vpc-958feff3"}}', '{"type": "READY"}', False, now(), True),
    ('nr-2', '10.1.0.0/16', 'us-west-2', '{"cloud": "aws", "region": "us-west-2", "zones": [{"name": "us-west-2a", "zone_id": "usw2-az1"}, {"name": "us-west-2b", "zone_id": "usw2-az2"}, {"name": "us-west-2c", "zone_id": "usw2-az3"}]}', 't0', '{"aws": {"account_id": "037803949979", "vpc_id": "vpc-abcdef12"}}', '{"type": "READY"}', True, now(), False),
    ('nr-3', '10.2.0.0/16', 'us-west-2', '{"cloud": "aws", "region": "us-west-2", "zones": [{"name": "us-west-2a", "zone_id": "usw2-az1"}]}', 't0', '{"aws": {"account_id": "037803949979", "vpc_id": "vpc-eff08497"}}', '{"type": "READY"}', False, now(), True),
    ('nr-4', '10.3.0.0/16', 'us-central1', '{"cloud": "gcp", "region": "us-central1", "zones": [{"name": "us-central1-b", "zone_id": "us-central1-b"}]}', 't0', '{"gcp": {"project_id": "cc-devel", "vpc_network_name": "k8s-test"}}', '{"type": "READY"}', False, now(), False),
    ('nr-5', '10.4.0.0/16', 'centralus', '{"cloud": "azure", "region": "centralus", "zones": [{"name": "centralus", "zone_id": "centralus"}]}', 't0', '{"azure": {"subscription_id": "a1-b2-c3-d4-e5", "vnet_id": "v-1"}}', '{"type": "READY"}', False, now(), False);

INSERT INTO deployment.k8s_cluster (id, network_region_id, config, created, modified, provider, k8saas_id)
VALUES
    ('k8s2', 'nr-1', '{"name": "k8s-mothership.us-west-2", "caas_version": "0.6.10", "is_schedulable": true, "img_pull_policy": "IfNotPresent"}', now(), now(), '{"cloud":"aws", "region":"us-west-2"}', 'k8s2'),
    ('k8s3', 'nr-2', '{"name": "k8s3.us-west-2", "caas_version": "0.6.10", "is_schedulable": true, "img_pull_policy": "IfNotPresent"}', now(), now(), '{"cloud":"aws", "region":"us-west-2"}', 'k8s3'),
    ('k8s4', 'nr-4', '{"name": "k8s4.us-central1", "caas_version": "0.6.10", "is_schedulable": true, "img_pull_policy": "IfNotPresent"}', now(), now(), '{"cloud":"aws", "region":"us-west-2"}', 'k8s4'),
    ('k8s5', 'nr-3', '{"name": "k8s5.us-west-2", "caas_version": "0.6.10", "is_schedulable": true, "img_pull_policy": "IfNotPresent"}', now(), now(), '{"cloud":"gcp", "region":"us-central1"}', 'k8s5'),
    ('k8s6', 'nr-5', '{"name": "k8s6.centralus", "caas_version": "0.6.10", "is_schedulable": true, "img_pull_policy": "IfNotPresent"}', now(), now(), '{"cloud":"azure", "region":"centralus"}', 'k8s6');


INSERT INTO cc_capacity_service.k8s_cluster (id, network_region_id, is_schedulable, created, modified, provider)
VALUES
    ('k8s2', 'nr-1', True, now(), now(), '{"cloud":"aws", "region":"us-west-2"}'),
    ('k8s3', 'nr-2', True, now(), now(), '{"cloud":"aws", "region":"us-west-2"}'),
    ('k8s4', 'nr-4', True, now(), now(), '{"cloud":"aws", "region":"us-west-2"}'),
    ('k8s5', 'nr-3', True, now(), now(), '{"cloud":"gcp", "region":"us-central1"}'),
    ('k8s6', 'nr-5', True, now(), now(), '{"cloud":"azure", "region":"centralus"}');

INSERT INTO cc_capacity_service.network_info (id, nid, cloud, realm, region, zone_ids, dedicated, deactivated, enable_sni, desired_connection_types, desired_state, actual_state, environment_id)
VALUES (1, 'nr-1', 'AWS', '037803949979', 'us-west-2', '{"usw2-az1", "usw2-az2", "usw2-az3"}', False, null, False, '{"PUBLIC", "VPC_PEERING", "TRANSIT_GATEWAY"}', 'ACTIVE', 'ACTIVE', 't0');
INSERT INTO cc_capacity_service.network_info (id, nid, cloud, realm, region, zone_ids, dedicated, deactivated, enable_sni, desired_connection_types, desired_state, actual_state, environment_id)
VALUES (2, 'nr-2', 'AWS', '037803949979', 'us-west-2', '{"usw2-az1", "usw2-az2", "usw2-az3"}', True, null, True, '{"PRIVATE_LINK"}', 'ACTIVE', 'ACTIVE', 't0');
INSERT INTO cc_capacity_service.network_info (id, nid, cloud, realm, region, zone_ids, dedicated, deactivated, enable_sni, desired_connection_types, desired_state, actual_state, environment_id)
VALUES (3, 's-hij56', 'AWS', '037803949979', 'us-west-2', '{"usw2-az1"}', True, null, False, '{"VPC_PEERING", "TRANSIT_GATEWAY"}', 'ACTIVE', 'ACTIVE', 't0');
INSERT INTO cc_capacity_service.network_info (id, nid, cloud, realm, region, zone_ids, dedicated, deactivated, enable_sni, desired_connection_types, desired_state, actual_state, environment_id)
VALUES (4, 's-klm78', 'GCP', 'cc-devel', 'us-central1', '{"us-central1-b"}', False, null, False, '{"PUBLIC"}', 'ACTIVE', 'ACTIVE', 't0');
INSERT INTO cc_capacity_service.network_info (id, nid, cloud, realm, region, zone_ids, dedicated, deactivated, enable_sni, desired_connection_types, desired_state, actual_state, environment_id)
VALUES (5, 's-xyz09', 'AZURE', 'a1-b2-c3-d4-e5', 'centralus', '{1}', False, null, False, '{"PUBLIC"}', 'ACTIVE', 'ACTIVE', 't0');

INSERT INTO cc_capacity_service.constraints (resource_id, cc_resource_type, constraint_types)
VALUES
    -- realms
    -- aws
    ('123', 'REALM', '{"DEFAULT"}'),
    ('realm-2', 'REALM', '{"DEFAULT"}'),
    ('321', 'REALM', '{"DEFAULT"}'),
    ('realm-4', 'REALM', '{"DEFAULT"}'),
    ('realm-5', 'REALM', '{"DEFAULT"}'),
    -- gcp
    ('realm-6', 'REALM', '{"DEFAULT"}'),
    ('realm-7', 'REALM', '{"DEFAULT"}'),
    ('realm-8', 'REALM', '{"DEFAULT"}'),
    ('realm-9', 'REALM', '{"DEFAULT"}'),
    ('realm-10', 'REALM', '{"DEFAULT"}'),
    -- azure
    ('realm-11', 'REALM', '{"DEFAULT"}'),
    ('realm-12', 'REALM', '{"DEFAULT"}'),
    ('realm-13', 'REALM', '{"DEFAULT"}'),
    ('realm-14', 'REALM', '{"DEFAULT"}'),
    ('realm-15', 'REALM', '{"DEFAULT"}'),

    -- networks
    ('nr-4','NETWORK','{"PUBLIC_SHARED"}'),
    ('nr-5','NETWORK','{"PUBLIC_SHARED"}'),

    -- k8s
    ('k8s4','KUBERNETES','{"PUBLIC_SHARED"}'),
    ('k8s6','KUBERNETES','{"PUBLIC_SHARED"}');
--
-- Stream Governance Region
--

CREATE SEQUENCE deployment.stream_governance_region_num START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE deployment.stream_governance_region_num OWNER TO caas;

CREATE TABLE deployment.stream_governance_region (
  id                      public.stream_governance_region_id PRIMARY KEY DEFAULT ('sgreg-' || NEXTVAL('deployment.stream_governance_region_num')::text),
  created                 timestamp without time zone DEFAULT now() NOT NULL,
  modified                timestamp without time zone DEFAULT now() NOT NULL,
  deactivated             timestamp without time zone DEFAULT NULL,
  region_id               public.region_id NOT NULL,
  environment_id          public.environment_id NOT NULL,
  config                  jsonb
);
ALTER TABLE deployment.stream_governance_region OWNER TO caas;

CREATE UNIQUE INDEX stream_governance_region_region_idx ON deployment.stream_governance_region USING btree (region_id) WHERE (deactivated IS NULL);

ALTER TABLE ONLY deployment.stream_governance_region ADD CONSTRAINT stream_governance_region_region_id_fkey FOREIGN KEY (region_id) REFERENCES deployment.region(id) NOT VALID;
ALTER TABLE ONLY deployment.stream_governance_region VALIDATE CONSTRAINT stream_governance_region_region_id_fkey;

ALTER TABLE ONLY deployment.stream_governance_region ADD CONSTRAINT stream_governance_region_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES deployment.environment(id) NOT VALID;
ALTER TABLE ONLY deployment.stream_governance_region VALIDATE CONSTRAINT stream_governance_region_environment_id_fkey;

-- The RBAC tables are maintained here: https://github.com/confluentinc/metadata-service/blob/master/rbac-db/src/test/resources/rbac_schema_postgres.sql
-- See https://github.com/confluentinc/metadata-service/blob/master/adrs/0004-cloud-rbac-db-schema-location.md

--
-- Name: rbac; Type: SCHEMA; Schema: -; Owner: cc_rbac_api
--

DO $$
BEGIN
  CREATE USER cc_rbac_api;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_rbac_api already exists -- skip create';
END
$$;

CREATE SCHEMA rbac;

ALTER SCHEMA rbac OWNER TO cc_rbac_api;

--
-- Name: extractor_events_kafka_message_sequence_id; Type: SEQUENCE; Schema: rbac; Owner: -
--

CREATE SEQUENCE rbac.extractor_events_kafka_message_sequence_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: extractor_publisher_state; Type: TABLE; Schema: rbac; Owner: -
--

CREATE TABLE rbac.extractor_publisher_state (
    events_kafka_message_sequence_id bigint NOT NULL,
    role_binding_last_change_id bigint NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    publish_type text
);


--
-- Name: role_binding; Type: TABLE; Schema: rbac; Owner: cc_rbac_api
--

CREATE TABLE rbac.role_binding (
    id text PRIMARY KEY,
    user_id text NOT NULL,
    role_name text NOT NULL,
    organization_id text,
    account_id text,
    cloud_cluster_id text,
    logical_cluster_id text,
    cluster_type text,
    resource_type text,
    resource_name text,
    pattern_type text,
    deleted boolean DEFAULT false NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    created_by text NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    modified_by text NOT NULL,
    last_change_id bigint NOT NULL default 1,
    reason jsonb
);

ALTER TABLE rbac.role_binding OWNER TO cc_rbac_api;
ALTER TABLE rbac.extractor_publisher_state OWNER TO cc_rbac_api;
ALTER TABLE rbac.extractor_events_kafka_message_sequence_id OWNER TO cc_rbac_api;

CREATE UNIQUE INDEX IF NOT EXISTS role_binding_last_change_id_idx on rbac.role_binding (last_change_id);

CREATE INDEX IF NOT EXISTS role_binding_scope_idx ON rbac.role_binding (organization_id, account_id, cloud_cluster_id, logical_cluster_id)
    WHERE deleted = false;
CREATE INDEX IF NOT EXISTS role_binding_user_idx ON rbac.role_binding (user_id, deleted);
CREATE UNIQUE INDEX IF NOT EXISTS role_binding_unique_idx ON rbac.role_binding (
    user_id,
    role_name,
    COALESCE(organization_id, ''),
    COALESCE(account_id, ''),
    COALESCE(cloud_cluster_id, ''),
    COALESCE(logical_cluster_id, ''),
    COALESCE(cluster_type, ''),
    COALESCE(resource_type, ''),
    COALESCE(resource_name, ''),
    COALESCE(pattern_type, ''))
    WHERE deleted = false;
--
-- Name: role_binding_id_seq; Type: SEQUENCE; Schema: rbac; Owner: cc_rbac_api
--

-- This sequence is used by the hashid generator that supplies the id
CREATE SEQUENCE rbac.role_binding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE rbac.role_binding_id_seq OWNER TO cc_rbac_api;

-- This sequence is used to generate a monotonically increasing value that can
-- be used by a Change Data Capture (CDC) process that propagates inserts, updates,
-- and (soft) deletes correctly to the data plane
CREATE SEQUENCE rbac.role_binding_last_change_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
--
-- Name: extractor_publisher_state extractor_publisher_state_pkey; Type: CONSTRAINT; Schema: rbac; Owner: -
--

ALTER TABLE ONLY rbac.extractor_publisher_state
    ADD CONSTRAINT extractor_publisher_state_pkey PRIMARY KEY (events_kafka_message_sequence_id);

--
-- Name: extractor_events_kafka_log_role_binding_last_change_id_idx; Type: INDEX; Schema: rbac; Owner: -
--

CREATE INDEX extractor_events_kafka_log_role_binding_last_change_id_idx ON rbac.extractor_publisher_state USING btree (role_binding_last_change_id);


ALTER TABLE rbac.role_binding_last_change_id_seq OWNER TO cc_rbac_api;

-- Function to enforce that last_change_id and modified are updated
CREATE OR REPLACE FUNCTION rbac.update_role_binding() RETURNS TRIGGER AS $body$
BEGIN
    NEW.last_change_id = nextval('rbac."role_binding_last_change_id_seq"');
    NEW.modified = NOW();
    RETURN NEW;
END $body$ LANGUAGE plpgsql;

-- Trigger to enforce that last_change_id and modified are updated
CREATE TRIGGER rbac_update_role_binding_trigger
 BEFORE INSERT OR UPDATE ON rbac.role_binding
 FOR EACH ROW
 -- there are currently no other triggers on this table, but this depth check
 -- prevents recursive loops if some are later added.
 WHEN (pg_trigger_depth() < 1)
 EXECUTE PROCEDURE rbac.update_role_binding();

INSERT INTO rbac.role_binding (id, user_id, role_name, created_by, modified_by) VALUES ('rb-s-000000', 'flowserviceadmin', 'CCloudRoleBindingAdmin', 'seed', 'seed');
INSERT INTO rbac.role_binding (id, user_id, role_name, created_by, modified_by) VALUES ('rb-s-000001', 'rbac-migrate-cli', 'CCloudRoleBindingAdmin', 'seed', 'seed');
-- 'rb-s-000002' was previously used for a schedulerserviceadamin role but has since been removed as it's no longer needed
INSERT INTO rbac.role_binding (id, user_id, role_name, created_by, modified_by) VALUES ('rb-s-000003', 'notificationserviceadmin', 'CCloudRoleBindingViewer', 'seed', 'seed');
INSERT INTO rbac.role_binding (id, user_id, role_name, created_by, modified_by) VALUES ('rb-s-000027', 'kafkaqueuesadmin', 'CCloudTopicRoleBindingAdmin', 'seed', 'seed');
INSERT INTO rbac.role_binding (id, user_id, role_name, created_by, modified_by) VALUES ('rb-s-000028', 'kafkaqueuesadmin', 'CCloudGroupRoleBindingAdmin', 'seed', 'seed');

-- The CDX tables are maintained here: https://github.com/confluentinc/cc-cdx-operations/blob/master/infra/cdx-db-operations/resources/schema.sql
--
-- Name: cdx; Type: SCHEMA; Schema: -; Owner: cc_cdx_api
--

DO $$
    BEGIN
        CREATE USER cc_cdx_api;
    EXCEPTION WHEN DUPLICATE_OBJECT THEN
        RAISE NOTICE 'user cc_cdx_api already exists -- skip create';
    END
$$;

CREATE SCHEMA cdx;

ALTER SCHEMA cdx OWNER TO cc_cdx_api;

CREATE TABLE cdx.stream_share
(
    id                          text                        NOT NULL,
    provider_org_resource_id    text                        NOT NULL,
    provider_environment_id     text                        NOT NULL,
    provider_logical_cluster_id text                        NOT NULL,
    provider_user_resource_id   text                        NOT NULL,
    consumer_org_resource_id    text,
    consumer_user_resource_id   text,
    consumer_restriction        jsonb                       DEFAULT '{}',
    status                      text                        NOT NULL,
    service_account_id          text,
    private_link_id             text,
    token                       text,
    delivery_method             jsonb                       DEFAULT '{}',
    created                     timestamp without time zone DEFAULT now() NOT NULL,
    modified                    timestamp without time zone DEFAULT now() NOT NULL,
    deactivated_at              timestamp without time zone,
    invite_expire_at            timestamp without time zone,
    redeemed_at                 timestamp without time zone
);

ALTER TABLE cdx.stream_share OWNER TO cc_cdx_api;

--
-- Name: stream_share_id_seq; Type: SEQUENCE; Schema: cdx; Owner: -
--

-- This sequence is used by the hashid generator that supplies the id
CREATE SEQUENCE cdx.stream_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cdx.stream_share_id_seq OWNER TO cc_cdx_api;

ALTER TABLE ONLY cdx.stream_share
    ADD CONSTRAINT cdx_stream_share_pkey PRIMARY KEY (id);

CREATE INDEX IF NOT EXISTS stream_share_created_idx ON cdx.stream_share (created);
CREATE INDEX IF NOT EXISTS stream_share_deactivated_at_idx ON cdx.stream_share (deactivated_at);
CREATE INDEX IF NOT EXISTS stream_share_provider_org_id_idx ON cdx.stream_share (provider_org_resource_id);
CREATE INDEX IF NOT EXISTS stream_share_consumer_org_id_idx ON cdx.stream_share (consumer_org_resource_id);
CREATE INDEX IF NOT EXISTS stream_share_token_idx ON cdx.stream_share (token);

CREATE TABLE cdx.shared_resource
(
    id                  text NOT NULL,
    org_resource_id     text NOT NULL,
    environment_id      text NOT NULL,
    logical_cluster_id  text NOT NULL,
    resource_name       text NOT NULL,
    resource_type       text NOT NULL,
    resource_crns       jsonb,
    service_account_id  text,
    resource_metadata   jsonb DEFAULT '{}',
    created             timestamp without time zone DEFAULT now() NOT NULL,
    modified            timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT cdx_shared_resource_pkey PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS cdx.shared_resource OWNER to cc_cdx_api;

CREATE INDEX IF NOT EXISTS shared_resource_created_idx ON cdx.shared_resource (created);
CREATE INDEX IF NOT EXISTS shared_resource_org_id_idx ON cdx.shared_resource (org_resource_id);
CREATE UNIQUE INDEX IF NOT EXISTS shared_resource_unique_idx ON cdx.shared_resource(org_resource_id, environment_id, logical_cluster_id, resource_type, resource_name);

-- This sequence is used by the hashid generator that supplies the id
CREATE SEQUENCE cdx.shared_resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cdx.shared_resource_id_seq OWNER TO cc_cdx_api;

CREATE TABLE cdx.stream_resource_mapping
(
    stream_share_id    text NOT NULL,
    shared_resource_id text NOT NULL,
    CONSTRAINT fk_stream_share_id FOREIGN KEY (stream_share_id)
        REFERENCES cdx.stream_share (id),
    CONSTRAINT fx_shared_resource_id FOREIGN KEY (shared_resource_id)
        REFERENCES cdx.shared_resource (id)
);
ALTER TABLE IF EXISTS cdx.stream_resource_mapping OWNER to cc_cdx_api;

CREATE UNIQUE INDEX IF NOT EXISTS stream_resource_mapping_share_resource_idx ON cdx.stream_resource_mapping(stream_share_id, shared_resource_id);
CREATE INDEX IF NOT EXISTS stream_resource_mapping_share_idx ON cdx.stream_resource_mapping(stream_share_id);
CREATE INDEX IF NOT EXISTS stream_resource_mapping_resource_idx ON cdx.stream_resource_mapping(shared_resource_id);

CREATE TABLE cdx.shared_resource_file
(
    shared_resource_id text  NOT NULL,
    file_name          text  NOT NULL,
    data               bytea NOT NULL
);
ALTER TABLE IF EXISTS cdx.shared_resource_file OWNER to cc_cdx_api;

CREATE UNIQUE INDEX IF NOT EXISTS shared_resource_file_unique_idx ON cdx.shared_resource_file(shared_resource_id, file_name);

CREATE SEQUENCE cdx.client_quota_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cdx.client_quota_id_seq OWNER TO cc_cdx_api;


CREATE TABLE cdx.feature_flag
(
    id              text NOT NULL,
    org_resource_id text NOT NULL,
    feature_name    text NOT NULL,
    feature_value   text NOT NULL,
    created         timestamp without time zone DEFAULT now() NOT NULL,
    modified        timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT cdx_feature_flag_pkey PRIMARY KEY (id)
);

ALTER TABLE IF EXISTS cdx.feature_flag OWNER to cc_cdx_api;

CREATE INDEX IF NOT EXISTS cdx_feature_flag_org_idx ON cdx.feature_flag(org_resource_id);

CREATE UNIQUE INDEX IF NOT EXISTS cdx_feature_flag_unique_idx ON cdx.feature_flag(org_resource_id, feature_name);

-- This sequence is used by the hashid generator that supplies the id
CREATE SEQUENCE cdx.feature_flag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cdx.feature_flag_id_seq OWNER TO cc_cdx_api;

-- The ARMS tables are maintained here: https://github.com/confluentinc/cc-cdx-operations/blob/master/infra/arms-db-operations/resources/schema.sql
--
-- Name: arms; Type: SCHEMA; Schema: -; Owner: cc_arms_api
--

DO $$
    BEGIN
        CREATE USER cc_arms_api;
    EXCEPTION WHEN DUPLICATE_OBJECT THEN
        RAISE NOTICE 'user cc_arms_api already exists -- skip create';
    END
$$;

CREATE SCHEMA arms;

ALTER SCHEMA arms OWNER TO cc_arms_api;

CREATE TYPE arms.request_status AS ENUM ('Pending', 'Approved', 'Rejected', 'Expired');
ALTER TYPE arms.request_status OWNER TO cc_arms_api;

CREATE SEQUENCE arms.request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE arms.request_id_seq OWNER TO cc_arms_api;

CREATE TABLE arms.request (
    id text PRIMARY KEY,
    org_resource_id text NOT NULL,
    status arms.request_status NOT NULL DEFAULT 'Pending',
    resources text [] NOT NULL check (resources <> '{}'),
    roles text [] NOT NULL check (roles <> '{}'),
    message text,
    created timestamp without time zone DEFAULT now() NOT NULL,
    created_by text NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    modified_by text NOT NULL,
    expire timestamp without time zone NOT NULL
);

ALTER TABLE arms.request OWNER TO cc_arms_api;

CREATE INDEX IF NOT EXISTS request_created_idx ON arms.request (created);
CREATE INDEX IF NOT EXISTS request_expire_idx ON arms.request (expire);
CREATE INDEX IF NOT EXISTS request_org_id_idx ON arms.request (org_resource_id);
CREATE INDEX IF NOT EXISTS requested_resource_idx ON arms.request USING GIN (resources);

-- Function to enforce that modified are updated
CREATE FUNCTION arms.update_request() RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.modified = NOW();
    RETURN NEW;
END
$$;

-- Trigger to enforce that modified is updated
CREATE TRIGGER arms_request_update_trigger
    BEFORE INSERT OR UPDATE ON arms.request
    FOR EACH ROW
    -- there are currently no other triggers on this table, but this depth check
    -- prevents recursive loops if some are later added.
    WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE arms.update_request();

-- The cloud growth tables are maintained here:https://github.com/confluentinc/cloud-growth-operations/blob/master/infra/db-operations/seed/cloudgrowthdb-seed.sql
--
-- Name: cloud_growth; Type: SCHEMA; Schema: -; Owner: caas
--
DO $$
    BEGIN
        CREATE USER cc_activation_status;
    EXCEPTION WHEN DUPLICATE_OBJECT THEN
        RAISE NOTICE 'user cc_activation_status already exists -- skip create';
    END
$$;

DO $$
    BEGIN
        CREATE USER cc_growth_service;
    EXCEPTION WHEN DUPLICATE_OBJECT THEN
        RAISE NOTICE 'user cc_growth_service already exists -- skip create';
    END
$$;

CREATE SCHEMA cloud_growth;

ALTER SCHEMA cloud_growth OWNER TO caas;
GRANT USAGE ON SCHEMA cloud_growth TO cc_activation_status;
GRANT USAGE ON SCHEMA cloud_growth TO cc_growth_service;

--
-- Name: activation_status_organization; Type: TABLE; Schema: cloud_growth; Owner: cc_activation_status
--
CREATE TABLE cloud_growth.activation_status_organization
(
    id                    BIGSERIAL,                                          -- id
    org_resource_id       VARCHAR(100)                              NOT null, -- organization resource-id
    org_id                integer                                   NOT NUll, -- organization id
    compute_date          timestamp without time zone               NOT null, -- the date when the production activation data is computed
    created               timestamp without time zone DEFAULT now() NOT NULL, -- the timestamp this row was created
    active                boolean                                   NOT NULL, -- if the org/cluster had at least one-byte throughput every day, for the last 7 days, end date is compute_date
    active_1gb            boolean                                   NOT NULL, -- if the org/cluster had at least 1GB throughput for the last 7 days, end date is compute_date
    l7d_num_active_days   integer                                   NOT NULL, -- number of days whose throughput is larger than 1 bytes in the last 7 days, end date is compute_date
    first_pa_date         timestamp without time zone,                        -- the first date of the org considered as production active stage 1 ever
    first_1gb_pa_date     timestamp without time zone,                        -- the first date of the org considered as production active stage 2 ever
    first_throughput_date timestamp without time zone,                        -- the first date of the org produced more than 1 bytes data (onboarding activated)
    usage_active          boolean                                   NOT NULL, -- if the org/cluster with a payment method enabled and had at least one-byte throughput every day, for the last 7 days, end date is compute_date
    usage_active_1gb      boolean                                   NOT NULL, -- if the org/cluster with a payment method enabled and had at least 1GB throughput for the last 7 days, end date is compute_date
    first_usage_pa_date         timestamp without time zone,                  -- the first date of the org considered as production active stage 1 ever (new PAO definition)
    first_usage_1gb_pa_date     timestamp without time zone                  -- the first date of the org considered as production active stage 2 ever (new PAO definition)
);
CREATE INDEX IF NOT EXISTS activation_status_organization_compute_date_org_resource_id_idx ON cloud_growth.activation_status_organization USING btree (compute_date DESC, org_resource_id);
CREATE INDEX IF NOT EXISTS activation_status_compute_date_org_id_idx ON cloud_growth.activation_status_organization USING btree (compute_date DESC, org_id);
ALTER TABLE cloud_growth.activation_status_organization OWNER TO cc_activation_status;

--
-- Name: activation_status_cluster; Type: TABLE; Schema: cloud_growth; Owner: cc_activation_status
--
CREATE TABLE cloud_growth.activation_status_cluster
(
    id                              BIGSERIAL,                                          -- id
    org_id                          integer                                   NOT NUll, -- organization id
    cluster_id                      varchar(32)                               NOT NULL, -- cluster_id for this cluster in this particular organization
    compute_date                    date                                      NOT NULL, -- specific day corresponding to this snapshot of cluster-level data
    active_days                     integer                                   NOT NULL, -- number of days this cluster has been production active, if applicable
    first_throughput_date           timestamp without time zone,                         -- first date of > 0 Mb throughput for this cluster)
    first_ingress_date              timestamp without time zone,                         -- first date of > 0 Mb ingress for this cluster)
    first_egress_date               timestamp without time zone,                         -- first date of > 0 Mb egress for this cluster
    active                          boolean                                   NOT NULL, -- if the cluster is production active, which means usage_active + a payment method is on file.
    active_100mb                    boolean                                   NOT NULL, -- if the cluster is production active at least 100Mb/day, which means usage_active + a payment method is on file.
    active_1gb                      boolean                                   NOT NULL, -- if the cluster is production active at least 1Gb/day, which means usage_active + a payment method is on file.
    active_10gb                     boolean                                   NOT NULL, -- if the cluster is production active at least 10Gb/day, which means usage_active + a payment method is on file.
    active_100gb                    boolean                                   NOT NULL, -- if the cluster is production active at least 100Gb/day, which means usage_active + a payment method is on file.
    active_1tb                      boolean                                   NOT NULL, -- if the cluster is production active at least 1Tb/day, which means usage_active + a payment method is on file.
    active_10tb                     boolean                                   NOT NULL, -- if the cluster is production active at least 10Tb/day, which means usage_active + a payment method is on file.
    first_pa_date                   timestamp without time zone,                        -- the first date of the cluster considered as production active stage 1 ever
    first_100mb_pa_date             timestamp without time zone,                        -- the first date that this cluster was production active > 100Mb/day
    first_1gb_pa_date               timestamp without time zone,                        -- the first date that this cluster was production active > 1Gb/day
    first_10gb_pa_date              timestamp without time zone,                        -- the first date that this cluster was production active > 10Gb/day
    first_100gb_pa_date             timestamp without time zone,                        -- the first date that this cluster was production active > 100Gb/day
    first_1tb_pa_date               timestamp without time zone,                        -- the first date that this cluster was production active > 1Tb/day
    first_10tb_pa_date              timestamp without time zone,                        -- the first date that this cluster was production active > 10Tb/day
    usage_active                    boolean                                   NOT NULL, -- whether or not the cluster is usage active - had at least one-byte throughput every day, for the last 7 days
    usage_active_100mb              boolean                                   NOT NULL, -- whether or not the cluster has had at least 100Mb throughput every day, for the last 7 days
    usage_active_1gb                boolean                                   NOT NULL, -- whether or not the cluster has had at least 1Gb throughput every day, for the last 7 days
    usage_active_10gb               boolean                                   NOT NULL, -- whether or not the cluster has had at least 10Gb throughput every day, for the last 7 days
    usage_active_100gb              boolean                                   NOT NULL, -- whether or not the cluster has had at least 100Gb throughput every day, for the last 7 days
    usage_active_1tb                boolean                                   NOT NULL, -- whether or not the cluster has had at least 1Tb throughput every day, for the last 7 days
    usage_active_10tb               boolean                                   NOT NULL, -- whether or not the cluster has had at least 10Tb throughput every day, for the last 7 days
    first_usage_active_date         timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active
    first_usage_active_100mb_date   timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active_100mb
    first_usage_active_1gb_date     timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active_1gb
    first_usage_active_10gb_date    timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active_10gb
    first_usage_active_100gb_date   timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active_100gb
    first_usage_active_1tb_date     timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active_1tb
    first_usage_active_10tb_date    timestamp without time zone,                        -- the initial date this cluster was first labeled as usage_active_10tb
    CONSTRAINT pk_activation_status_cluster PRIMARY KEY (id, compute_date)
);
CREATE INDEX IF NOT EXISTS activation_status_cluster_compute_date_cluster_id_idx ON cloud_growth.activation_status_cluster USING btree (compute_date DESC, cluster_id);
CREATE INDEX IF NOT EXISTS activation_status_cluster_compute_date_org_id_cluster_id_idx ON cloud_growth.activation_status_cluster USING btree (compute_date DESC, org_id, cluster_id);
ALTER TABLE cloud_growth.activation_status_cluster OWNER TO cc_activation_status;

--
-- Name: campaign_promo_code; Type: TABLE; Schema: cloud_growth; Owner: cc_growth_service
--
CREATE TABLE cloud_growth.campaign_promo_code
(
    id                 BIGSERIAL PRIMARY KEY,                              -- id
    promo_code         VARCHAR(50)                               NOT NULL, -- promo code
    org_resource_id    TEXT                                      NOT NULL, -- organization resource-id
    org_id             integer                                   NOT NUll, -- organization id
    created_by_user_id integer                                   NOT NULL, -- createdBy user id
    campaign_type      VARCHAR(50)                               NOT NULL, -- campaign_type： "Invitation", "Client", "Tutorial", or "SourceConnector".
    status             VARCHAR(50)                               NOT NULL, -- status of the promo code: Pending, Created, Failed
    created            timestamp without time zone DEFAULT now() NOT NULL, -- the timestamp this row was created
    modified           timestamp without time zone DEFAULT now() NOT NULL  -- the timestamp this row was modified
);
CREATE INDEX IF NOT EXISTS campaign_promo_code_org_resource_id_idx ON cloud_growth.campaign_promo_code USING btree (org_resource_id);
CREATE INDEX IF NOT EXISTS campaign_promo_code_org_id_idx ON cloud_growth.campaign_promo_code USING btree (org_id);
CREATE INDEX IF NOT EXISTS campaign_promo_code_org_resource_id_campaign_type_idx ON cloud_growth.campaign_promo_code USING btree (org_resource_id, campaign_type);
CREATE INDEX IF NOT EXISTS campaign_promo_code_org_id_campaign_type_idx ON cloud_growth.campaign_promo_code USING btree (org_id, campaign_type);
CREATE INDEX IF NOT EXISTS campaign_promo_code_org_resource_id_campaign_type_user_id_idx ON cloud_growth.campaign_promo_code USING btree (org_resource_id, campaign_type, created_by_user_id);
CREATE INDEX IF NOT EXISTS campaign_promo_code_org_id_campaign_type_user_id_idx ON cloud_growth.campaign_promo_code USING btree (org_id, campaign_type, created_by_user_id);
CREATE INDEX IF NOT EXISTS campaign_promo_code_promo_code_idx ON cloud_growth.campaign_promo_code USING btree (promo_code);
ALTER TABLE cloud_growth.campaign_promo_code OWNER TO cc_growth_service;
ALTER TABLE cloud_growth.campaign_promo_code ADD CONSTRAINT unique_campaign_promo_code UNIQUE (promo_code);

--
-- Name: campaign_flow; Type: TABLE; Schema: cloud_growth; Owner: cc_growth_service
--
CREATE TABLE cloud_growth.campaign_flow
(
    id               BIGSERIAL PRIMARY KEY,                                    -- id
    flow_resource_id VARCHAR(50)                                     NOT NULL, -- flow_resource_id
    org_resource_id  TEXT                                            NOT NULL, -- organization resource-id
    org_id           integer                                         NOT NUll, -- organization id
    user_id          integer                                         NOT NULL, -- user id
    campaign_type    VARCHAR(50)                                     NOT NULL, -- campaign_type： "Invitation", "Client", "Tutorial", or "SourceConnector".
    status           VARCHAR(50)                                     NOT NULL, -- status of the flow: COMPLETED, IN_PROGRESS
    created          timestamp without time zone DEFAULT now()       NOT NULL, -- the timestamp this row was created
    modified         timestamp without time zone DEFAULT now()       NOT NULL, -- the timestamp this row was modified
    validations      jsonb                       DEFAULT '{}'::jsonb NOT NULL
);
CREATE INDEX IF NOT EXISTS campaign_flow_org_resource_id_idx ON cloud_growth.campaign_flow USING btree (org_resource_id);
CREATE INDEX IF NOT EXISTS campaign_flow_org_id_idx ON cloud_growth.campaign_flow USING btree (org_id);
CREATE INDEX IF NOT EXISTS campaign_flow_org_resource_id_campaign_type_idx ON cloud_growth.campaign_flow USING btree (org_resource_id, campaign_type);
CREATE INDEX IF NOT EXISTS campaign_flow_org_id_campaign_type_idx ON cloud_growth.campaign_flow USING btree (org_id, campaign_type);
CREATE INDEX IF NOT EXISTS campaign_flow_org_resource_id_campaign_type_user_id_idx ON cloud_growth.campaign_flow USING btree (org_resource_id, campaign_type, user_id);
CREATE INDEX IF NOT EXISTS campaign_flow_org_id_campaign_type_user_id_idx ON cloud_growth.campaign_flow USING btree (org_id, campaign_type, user_id);
CREATE INDEX IF NOT EXISTS campaign_flow_promo_code_idx ON cloud_growth.campaign_flow USING btree (flow_resource_id);
ALTER TABLE cloud_growth.campaign_flow OWNER TO cc_growth_service;
ALTER TABLE cloud_growth.campaign_flow ADD CONSTRAINT unique_campaign_flow_flow_record_with_org_resource_id UNIQUE (org_resource_id, campaign_type, user_id, flow_resource_id);
ALTER TABLE cloud_growth.campaign_flow ADD CONSTRAINT unique_campaign_flow_flow_record_with_org_id UNIQUE (org_id, campaign_type, user_id, flow_resource_id);

CREATE SEQUENCE IF NOT EXISTS cloud_growth.promo_code_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE cloud_growth.promo_code_id_seq OWNER TO cc_growth_service;

--
-- Start Atlas tables --
--

CREATE SCHEMA atlas;
ALTER SCHEMA atlas OWNER TO caas;

CREATE SEQUENCE IF NOT EXISTS atlas.certificate_scheme_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE atlas.certificate_scheme_num OWNER TO caas;

CREATE TABLE IF NOT EXISTS atlas.certificate_scheme
(
    id                          text PRIMARY KEY DEFAULT ('cs-' || nextval('atlas.certificate_scheme_num')::text),
    name                        text NOT NULL,
    created                     timestamp without time zone DEFAULT now() NOT NULL,
    modified                    timestamp without time zone DEFAULT now() NOT NULL,
    deactivated                 timestamp without time zone DEFAULT NULL,
    enable_preallocation        text NOT NULL,
    enable_recycle              boolean,
    domain_elements             jsonb DEFAULT '{}' NOT NULL,
    is_shareable                boolean DEFAULT false,
    internal_domain_elements    jsonb,
    custom_domain_token_map     jsonb DEFAULT '{}' NOT NULL
);
ALTER TABLE atlas.certificate_scheme OWNER TO caas;

CREATE SEQUENCE IF NOT EXISTS atlas.certificate_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE atlas.certificate_num OWNER TO caas;

CREATE SEQUENCE IF NOT EXISTS atlas.domain_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE atlas.domain_num OWNER TO caas;

CREATE SEQUENCE IF NOT EXISTS atlas.internal_domain_num START WITH 1 INCREMENT 1 NO CYCLE NO MINVALUE NO MAXVALUE;
ALTER TABLE atlas.internal_domain_num OWNER TO caas;

CREATE TABLE IF NOT EXISTS atlas.certificate
(
    id                      text PRIMARY KEY DEFAULT ('cert-' || nextval('atlas.certificate_num')::text),
    certificate_scheme_id   text NOT NULL,
    created                 timestamp without time zone DEFAULT now() NOT NULL,
    modified                timestamp without time zone DEFAULT now() NOT NULL,
    deactivated             timestamp without time zone DEFAULT NULL,
    revoked                 timestamp without time zone DEFAULT NULL,
    start                   timestamp without time zone NOT NULL,
    expiry                  timestamp without time zone NOT NULL,
    cloud                   public.cloud_id NOT NULL,
    region                  public.region_id NOT NULL,
    issuer_id               text NOT NULL,
    issuer_account_id       text NOT NULL,
    storage_type            text NOT NULL,
    storage_location        text NOT NULL,
    domain_id               text DEFAULT ('dom-' || nextval('atlas.domain_num')::text),
    domain_list             text[] DEFAULT array[]::text[] NOT NULL,
    internal_domain_list    text[] DEFAULT array[]::text[]
);
ALTER TABLE ONLY atlas.certificate ADD CONSTRAINT certificate_scheme_id_fkey FOREIGN KEY (certificate_scheme_id) REFERENCES atlas.certificate_scheme(id) NOT VALID;
ALTER TABLE ONLY atlas.certificate VALIDATE CONSTRAINT certificate_scheme_id_fkey;
ALTER TABLE atlas.certificate OWNER TO caas;

CREATE TABLE IF NOT EXISTS atlas.certificate_owner
(
    certificate_id      text NOT NULL,
    owner_id            text NOT NULL,
    created             timestamp without time zone DEFAULT now() NOT NULL,
    deactivated         timestamp without time zone DEFAULT NULL
);
ALTER TABLE atlas.certificate_owner OWNER TO caas;

--
-- End Atlas tables --
--

--
-- Start seed Atlas tables --
--
insert into atlas.certificate_scheme (id, name, created, modified, enable_preallocation, enable_recycle, domain_elements)
VALUES
('cs-1', 'network_scoped_certificate_scheme', now(), now(), 'REGION', false, '[["WILDCARD", "DOMAIN_ID", "REGION", "CLOUD", "TOP_LEVEL_DOMAIN"], ["WILDCARD", "ZONE", "DOMAIN_ID", "REGION", "CLOUD", "TOP_LEVEL_DOMAIN"]]');

--
-- End seed Atlas tables --
--
/* Start Mothership State Seeding */
-- Seeding necessary records for mothership kafka to have debezium connector
-- Note: Some of mothership pkc record config is set in cc-postgres k8s job

/* create deployment for mothership lkc */
/* note that the network region is set to nr-1 here but reset to nr-100 in cc-postgres */
/* it cannot be set just here as that network region is not created but these other resources cannot be seeded without an nr*/
INSERT INTO deployment.deployment (id, created, modified, deactivated, account_id, network_access, sku, network_region_id, provider, dedicated)
VALUES
('deployment-mothership', now(), now(), null, 't0','{"vpc_peering": [{"enabled": true}], "public_internet": [{"enabled": true}]}', 'DEDICATED_LEGACY', 'nr-1', '{"cloud": "gcp", "region": "us-central1"}', true),
('deployment-caas', now(), now(), null, 't0','{"vpc_peering": [{"enabled": true}], "public_internet": [{"enabled": true}]}', 'DEDICATED_LEGACY', 'nr-1', '{"cloud": "gcp", "region": "us-central1"}', true),
('deployment-logs', now(), now(), null, 't0','{"vpc_peering": [{"enabled": true}], "public_internet": [{"enabled": true}]}', 'DEDICATED_LEGACY', 'nr-1', '{"cloud": "gcp", "region": "us-central1"}', true),
('deployment-scraper', now(), now(), null, 't0','{"vpc_peering": [{"enabled": true}], "public_internet": [{"enabled": true}]}', 'DEDICATED_LEGACY', 'nr-1', '{"cloud": "gcp", "region": "us-central1"}', true),
('deployment-router', now(), now(), null, 't0','{"vpc_peering": [{"enabled": true}], "public_internet": [{"enabled": true}]}', 'DEDICATED_LEGACY', 'nr-1', '{"cloud": "gcp", "region": "us-central1"}', true);

/* create record for mothership pkc */
/* k8s must be set in cc-postgres to k8s-42 */
INSERT INTO deployment.physical_cluster(id, k8s_cluster_id, type,  deactivated, created, modified, is_schedulable, network_isolation_domain_id, sni_enabled, config, provider)
VALUES 
('pkc-mothership', 'k8s2', 'kafka', null, now(), now(), true, null, false, '{ "ksql": null, "spec": null, "version": null, "kafka": { "enterprise": true, "dedicated": true, "durability": "HIGH", "storage": 1000000, "image": "", "internal": false, "pods": [{ "num":0, "name": "kafka-0" }, { "num":1, "name": "kafka-1" }, { "num":2, "name":"kafka-2" }], "zones": [{}], "zone_to_proxy": null, "external_endpt_str": "place-holder-set-in-cc-postgres-job", "internal_endpt_str": "PLAINTEXT://kafka-0.kafka.pkc-mothership.svc.cluster.local:9071,kafka-1.kafka.pkc-mothership.svc.cluster.local:9071,kafka-2.kafka.pkc-mothership.svc.cluster.local:9071", "renewed_cert_at": "0001-01-01T00:00:00Z", "ssl_certificate_id": "", "external_client_protocol": "", "external_listener_protocol":"", "zookeeper_id": "pzkc-mothership", "legacy_endpoint": true, "internal_proxy": false, "storage_capacity": 1000, "options": { "image": {}, "enable_quota": { "value": true }, "jws_public_key": { "value": "" } }, "enable_kafka_api": true, "kafka_api_id": "pkac-q3z1dz9", "enable_data_balancer": true, "data_balancer_id": "", "healthcheck_logical_cluster_id": "lkc-xxxxx", "tiered_storage_service_account_secret_id": { "Int64": 0, "Valid": false } }, "connect": { "pods": null, "spec": {}, "zones": null, "options": {}, "version": null, "enterprise": false, "iam_user_arn": "", "kafka_api_key": "", "kafka_cluster_id": "" }, "kafka-api": { "pods": null, "spec": {}, "zones": null, "options": {}, "version": null, "kafka_cluster_id": "", "external_api_str": "" }, "zookeeper": { "pods": null, "spec": {}, "zones": null, "version": null, "servers_str": "", "storage_capacity": 0 }, "databalancer": { "pods": null, "spec": {}, "zones": null, "options": {}, "version": null, "physical_cluster_id": "", "replication_throttle_bytes_per_sec": 0, "self_healing_goal_violation_enabled": false }, "cert_secret_id": 119693, "schema-registry": { "pods": null, "spec": {}, "zones": null, "global": false, "options": {}, "version": null, "enterprise": false, "feature_flags": null, "internal_proxy": false, "schemas_kafka_api_key": "", "schemas_kafka_cluster_id": "" }, "service_account": null }', '{"cloud":"aws", "region":"us-west-2"}'),
('pcc-mothership', 'k8s2', 'connect', null, now(), now(), true, null, false, '{ "ksql": null, "spec": null, "version": null, "kafka": { "enterprise": true, "dedicated": true, "durability": "HIGH", "storage": 1000000, "image": "", "internal": false, "pods": [{ "num":0, "name": "kafka-0" }, { "num":1, "name": "kafka-1" }, { "num":2, "name":"kafka-2" }], "zones": [{}], "zone_to_proxy": null, "external_endpt_str": "place-holder-set-in-cc-postgres-job", "internal_endpt_str": "PLAINTEXT://kafka-0.kafka.pkc-mothership.svc.cluster.local:9071,kafka-1.kafka.pkc-mothership.svc.cluster.local:9071,kafka-2.kafka.pkc-mothership.svc.cluster.local:9071", "renewed_cert_at": "0001-01-01T00:00:00Z", "ssl_certificate_id": "", "external_client_protocol": "", "external_listener_protocol":"", "zookeeper_id": "pzkc-mothership", "legacy_endpoint": true, "internal_proxy": false, "storage_capacity": 1000, "options": { "image": {}, "enable_quota": { "value": true }, "jws_public_key": { "value": "" } }, "enable_kafka_api": true, "kafka_api_id": "pkac-q3z1dz9", "enable_data_balancer": true, "data_balancer_id": "", "healthcheck_logical_cluster_id": "lkc-xxxxx", "tiered_storage_service_account_secret_id": { "Int64": 0, "Valid": false } }, "connect": { "pods": null, "spec": {}, "zones": null, "options": {}, "version": null, "enterprise": false, "iam_user_arn": "", "kafka_api_key": "", "kafka_cluster_id": "" }, "kafka-api": { "pods": null, "spec": {}, "zones": null, "options": {}, "version": null, "kafka_cluster_id": "", "external_api_str": "" }, "zookeeper": { "pods": null, "spec": {}, "zones": null, "version": null, "servers_str": "", "storage_capacity": 0 }, "databalancer": { "pods": null, "spec": {}, "zones": null, "options": {}, "version": null, "physical_cluster_id": "", "replication_throttle_bytes_per_sec": 0, "self_healing_goal_violation_enabled": false }, "cert_secret_id": 119693, "schema-registry": { "pods": null, "spec": {}, "zones": null, "global": false, "options": {}, "version": null, "enterprise": false, "feature_flags": null, "internal_proxy": false, "schemas_kafka_api_key": "", "schemas_kafka_cluster_id": "" }, "service_account": null }', '{"cloud":"aws", "region":"us-west-2"}');

INSERT INTO deployment.physical_cluster_status(id, status, status_detail, status_modified, status_received, last_initialized, last_deleted)
VALUES ('pkc-mothership', 'UP', '{"PSCStatus": {"phase": "RUNNING", "summary": "UP"}, "IsExpansionInitiated": false}', null, null, null, null),
       ('pcc-mothership', 'UP', '{"PSCStatus": {"phase": "RUNNING", "summary": "UP"}, "IsExpansionInitiated": false}', null, null, null, null);

/* create logical cluster record */
INSERT INTO deployment.logical_cluster(id, name, physical_cluster_id, type, account_id, config, created, modified, deactivated, deployment_id, organization_id, org_resource_id, region, cloud, network_id, sku)
VALUES
( 'lkc-mothership','mothership','pkc-mothership','kafka','t0','{"kafka": {"durability": "HIGH", "enterprise": true, "network_egress": 1, "network_ingress": 1, "storage_capacity": 1000}, "connector": {"user_configs": null, "connector_name": "", "connector_type": ""}, "price_per_hour": 7904, "schema_registry": {"MaxSchemas": 0, "kafka_cluster_id": ""}, "accrued_this_cycle": 0}','2018-10-22 16:14:22.576176','2021-01-12 06:47:23.415694',null,'deployment-mothership', 0, '00000000-0000-0000-0000-000000000000', 'us-central1', 'gcp', 'nr-1', 'DEDICATED_LEGACY'),
( 'lcc-mothership','mothership','pcc-mothership','connect','t0','{"kafka": {"durability": "HIGH", "enterprise": true, "network_egress": 1, "network_ingress": 1, "storage_capacity": 1000}, "connector": {"user_configs": null, "connector_name": "", "connector_type": ""}, "price_per_hour": 7904, "schema_registry": {"MaxSchemas": 0, "kafka_cluster_id": ""}, "accrued_this_cycle": 0}','2018-10-22 16:14:22.576176','2021-01-12 06:47:23.415694',null,'deployment-mothership', 0, '00000000-0000-0000-0000-000000000000', 'us-central1', 'gcp', 'nr-1', 'DEDICATED_LEGACY'),
( 'lkc-caas','lkc-caas','pkc-mothership','kafka','t0','{"kafka": {"durability": "HIGH", "enterprise": true, "network_egress": 1, "network_ingress": 1, "storage_capacity": 1000}, "connector": {"user_configs": null, "connector_name": "", "connector_type": ""}, "price_per_hour": 7904, "schema_registry": {"MaxSchemas": 0, "kafka_cluster_id": ""}, "accrued_this_cycle": 0}','2018-10-22 16:14:22.576176','2021-01-12 06:47:23.415694',null,'deployment-caas', 0, '00000000-0000-0000-0000-000000000000', 'us-central1', 'gcp', 'nr-1', 'DEDICATED_LEGACY'),
( 'lkc-logs','lkc-logs','pkc-mothership','kafka','t0','{"kafka": {"durability": "HIGH", "enterprise": true, "network_egress": 1, "network_ingress": 1, "storage_capacity": 1000}, "connector": {"user_configs": null, "connector_name": "", "connector_type": ""}, "price_per_hour": 7904, "schema_registry": {"MaxSchemas": 0, "kafka_cluster_id": ""}, "accrued_this_cycle": 0}','2018-10-22 16:14:22.576176','2021-01-12 06:47:23.415694',null,'deployment-logs', 0, '00000000-0000-0000-0000-000000000000', 'us-central1', 'gcp', 'nr-1', 'DEDICATED_LEGACY'),
( 'lkc-scraper','lkc-scraper','pkc-mothership','kafka','t0','{"kafka": {"durability": "HIGH", "enterprise": true, "network_egress": 1, "network_ingress": 1, "storage_capacity": 1000}, "connector": {"user_configs": null, "connector_name": "", "connector_type": ""}, "price_per_hour": 7904, "schema_registry": {"MaxSchemas": 0, "kafka_cluster_id": ""}, "accrued_this_cycle": 0}','2018-10-22 16:14:22.576176','2021-01-12 06:47:23.415694',null,'deployment-scraper', 0, '00000000-0000-0000-0000-000000000000', 'us-central1', 'gcp', 'nr-1', 'DEDICATED_LEGACY'),
( 'lkc-router','lkc-router','pkc-mothership','kafka','t0','{"kafka": {"durability": "HIGH", "enterprise": true, "network_egress": 1, "network_ingress": 1, "storage_capacity": 1000}, "connector": {"user_configs": null, "connector_name": "", "connector_type": ""}, "price_per_hour": 7904, "schema_registry": {"MaxSchemas": 0, "kafka_cluster_id": ""}, "accrued_this_cycle": 0}','2018-10-22 16:14:22.576176','2021-01-12 06:47:23.415694',null,'deployment-router', 0, '00000000-0000-0000-0000-000000000000', 'us-central1', 'gcp', 'nr-1', 'DEDICATED_LEGACY');

INSERT INTO deployment.logical_cluster_status(id, status_detail, status_modified)
VALUES
('lkc-mothership', '{}', '2019-03-14 18:30:18.345204'),
('lcc-mothership', '{}', '2019-03-14 18:30:18.345204'),
('lkc-caas', '{}', '2019-03-14 18:30:18.345204'),
('lkc-logs', '{}', '2019-03-14 18:30:18.345204'),
('lkc-scraper', '{}', '2019-03-14 18:30:18.345204'),
('lkc-router', '{}', '2019-03-14 18:30:18.345204');

/* Add user to create debezium connector */
INSERT INTO deployment.users(id, resource_id, email, first_name, last_name, verified, created, modified)
VALUES
(73508, 'u-1010101010', 'CDCPipeline+debezium@confluent.io', 'CDCPipeline', 'CDCPipeline', now(), now(), now());

/* Add data needed for cc_networking_service.
 * Networking service in CPD relies on the code to read from obelisk DB that has references to public schema.
 * Hence adding the required tables in public schema.
 */
--
-- Name: hstore; Type: EXTENSION; Schema: public; Owner: cc_networking_service
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: public; Owner: cc_networking_service
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';

------------------------------------------------------------
------------------------------------------------------------
--
-- Table cert_registry
--

CREATE TABLE IF NOT EXISTS deployment.cert_registry (
    id serial PRIMARY KEY,
    k8s_id public.k8s_cluster_id NOT NULL REFERENCES deployment.k8s_cluster (id),
    k8s_namespace varchar(64) NOT NULL,
    secret_id INTEGER NOT NULL REFERENCES deployment.secret (id),
    created timestamp without time zone DEFAULT now() NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    deactivated timestamp without time zone
);

CREATE INDEX IF NOT EXISTS k8s_id_idx ON deployment.cert_registry (k8s_id);
CREATE INDEX IF NOT EXISTS secret_id_idx ON deployment.cert_registry (secret_id);

ALTER TABLE deployment.cert_registry OWNER TO caas;

--
-- Name: sites; Type: TABLE; Schema: public; Owner: cc_networking_service
--

CREATE TABLE public.sites (
    id integer NOT NULL PRIMARY KEY,
    name character varying(63),
    nid text NOT NULL,
    cloud text NOT NULL,
    region text NOT NULL,
    cidr cidr NOT NULL,
    zone_ids text[],
    desired_state text NOT NULL,
    actual_state text NOT NULL,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    actual_modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    enable_sni boolean DEFAULT true NOT NULL,
    network_version text DEFAULT ''::text NOT NULL,
    realm text DEFAULT ''::text NOT NULL,
    network_name text NOT NULL,
    aws_subnets_public json,
    aws_subnets_private json,
    last_error_msg text DEFAULT ''::text NOT NULL,
    last_error_code integer DEFAULT 0 NOT NULL,
    access_public boolean DEFAULT false NOT NULL,
    access_private boolean DEFAULT false NOT NULL,
    access_private_link_through_private_nlb boolean DEFAULT false NOT NULL,
    egress_ips_active boolean DEFAULT false NOT NULL,
    aws_egress_ip_configs json,
    environment_id text DEFAULT ''::text NOT NULL,
    display_name text DEFAULT ''::text NOT NULL,
    connection_types text[] DEFAULT '{}'::text[] NOT NULL,
    dedicated boolean DEFAULT true NOT NULL,
    cloud_egress_ips cidr[] DEFAULT '{}'::cidr[] NOT NULL,
    cloud_dns_domain text DEFAULT ''::text NOT NULL,
    cloud_zonal_domains public.hstore,
    cloud_glb_zone_suffixes public.hstore,
    cloud_aws_vpc_id text DEFAULT ''::text NOT NULL,
    cloud_aws_privatelink_endpoint_service text DEFAULT ''::text NOT NULL,
    cloud_gcp_vpc_network_name text DEFAULT ''::text NOT NULL,
    cloud_azure_vnet_name text DEFAULT ''::text NOT NULL,
    cloud_azure_vnet_resource_group_name text DEFAULT ''::text NOT NULL,
    cloud_azure_private_link_service_alias public.hstore,
    deactivated timestamp without time zone,
    nsoft integer DEFAULT 0,
    nhard integer DEFAULT 0,
    managed boolean DEFAULT true NOT NULL,
    was_active boolean DEFAULT false NOT NULL,
    cert_type integer DEFAULT 0 NOT NULL,
    cert_id text DEFAULT ''::text NOT NULL,
    cert_dns_unique_id text DEFAULT ''::text NOT NULL,
    cert_san_list text[],
    desired_connection_types text[] DEFAULT '{}'::text[] NOT NULL,
    status_connection_types text[] DEFAULT '{}'::text[] NOT NULL,
    billable_connection_type text DEFAULT ''::text NOT NULL,
    terraform_target text DEFAULT ''::text,
    cloud_gcp_psc_service_attachments public.hstore,
    is_idle boolean DEFAULT true NOT NULL,
    gcp_additional_pod_cidrs json,
    gcp_cloud_nats json,
    reconcile_priority integer DEFAULT 1 NOT NULL,
    org_deactivated timestamp without time zone,
    cloud_azure_private_link_service_resource_ids public.hstore,
    envoy_instance_pools json,
    traffic_runtime_config jsonb,
    multi_tc_enabled boolean DEFAULT false,
    cloud_azure_should_refresh_vmss boolean DEFAULT false,
    spec_zone_info json,
    aws_reserved_cidr text,
    cloud_aws_bridge_vpc_id text,
    azure_resource_group_name text DEFAULT ''::text NOT NULL
);

/* Seed required data into public.sites table. */
/* This data is ported over from deployment.network_region table to conform to the schema of public.sites table */

INSERT INTO public.sites (id, name, nid, cloud, region, cidr, zone_ids, desired_state, actual_state, enable_sni, network_version, realm, network_name, access_public, access_private, access_private_link_through_private_nlb, environment_id, display_name, connection_types, dedicated, cloud_dns_domain, cloud_zonal_domains, cloud_glb_zone_suffixes, cloud_aws_vpc_id, cloud_gcp_vpc_network_name, cloud_azure_vnet_name, desired_connection_types, status_connection_types, billable_connection_type)
VALUES
(1,  's-abc12', 'nr-1', 'aws', 'us-west-2', '10.0.0.0/16', '{"usw2-az1", "usw2-az2", "usw2-az3"}', 'active', 'active', False, 'v3', '037803949979',  's-abc12', False, False, False, 't0', 'nr-1', '{"VPC_PEERING", "TRANSIT_GATEWAY"}', True, 'abc12.us-west-2.aws.priv.cpdev.cloud', '"usw2-az1"=>"usw2-az1.abc12.us-west-2.aws.priv.cpdev.cloud", "usw2-az2"=>"usw2-az2.abc12.us-west-2.aws.priv.cpdev.cloud", "usw3-az3"=>"usw3-az3.abc12.us-west-2.aws.priv.cpdev.cloud"', '"usw2-az1"=>"usw2-az1-abc12.us-west-2.aws.glb.priv.cpdev.cloud", "usw2-az2"=>"usw2-az2-abc12.us-west-2.aws.glb.priv.cpdev.cloud", "usw3-az3"=>"usw3-az3-abc12.us-west-2.aws.glb.priv.cpdev.cloud"', 'vpc-958feff3', '', '', '{"VPC_PEERING", "TRANSIT_GATEWAY"}', '{}', 'VPC_PEERING'),
(2, 's-def34', 'nr-2', 'aws', 'us-west-2', '10.1.0.0/16', '{"usw2-az1", "usw2-az2", "usw2-az3"}', 'active', 'active', True, 'v4', '037803949979',  's-def34', True, False, False, 't0', 'nr-2', '{"PRIVATE_LINK"}', False, 'def34.us-west-2.aws.priv.cpdev.cloud', '"usw2-az1"=>"usw2-az1.def34.us-west-2.aws.priv.cpdev.cloud", "usw2-az2"=>"usw2-az2.def34.us-west-2.aws.priv.cpdev.cloud", "usw3-az3"=>"usw3-az3.def34.us-west-2.aws.priv.cpdev.cloud"', '"usw2-az1"=>"usw2-az1-def34.us-west-2.aws.glb.priv.cpdev.cloud", "usw2-az2"=>"usw2-az2-def34.us-west-2.aws.glb.priv.cpdev.cloud", "usw3-az3"=>"usw3-az3-def34.us-west-2.aws.glb.priv.cpdev.cloud"', 'vpc-abcdef12', '', '', '{"PRIVATE_LINK"}', '{}', 'PRIVATE_LINK'),
(3,  's-hij56', 'nr-3', 'aws', 'us-west-2', '10.2.0.0/16', '{"usw2-az1"}', 'active', 'active', False, 'v3', '037803949979',  's-hij56', False, False, False, 't0', 'nr-3', '{"VPC_PEERING", "TRANSIT_GATEWAY"}', True,'hij56.us-west-2.aws.priv.cpdev.cloud', '"usw2-az1"=>"usw2-az1.abc12.us-west-2.aws.priv.cpdev.cloud"', '"usw2-az1"=>"usw2-az1-hij56.us-west-2.aws.glb.priv.cpdev.cloud"', 'vpc-eff08497', '', '', '{"VPC_PEERING", "TRANSIT_GATEWAY"}', '{}', 'VPC_PEERING'),
(4,  's-klm78', 'nr-4', 'gcp', 'us-central1', '10.3.0.0/16', '{"us-central1-b"}', 'active', 'active', False, 'v3', 'cc-devel',  's-klm78', False, False, False, 't0', 'nr-4', '{"PUBLIC"}', False, 'klm78.us-central1.gcp.priv.cpdev.cloud', '"us-central1-b"=>"us-central1-b.klm78.us-central1.gcp.priv.cpdev.cloud"', '"us-central1-b"=>"us-central1-b-klm78.us-central1.gcp.glb.priv.cpdev.cloud"', '', 'k8s-test', '', '{"PUBLIC"}', '{}', 'PUBLIC'),
(5,  's-xyz09', 'nr-5', 'azure', 'centralus', '10.4.0.0/16', '{1}', 'active', 'active', False, 'v3', 'a1-b2-c3-d4-e5',  's-xyz09', False, False, False, 't0', 'nr-5', '{"PUBLIC"}', False, 'xyz09.centralus.azure.priv.cpdev.cloud', '"1"=>"az1.xyz09.centralus.azure.priv.cpdev.cloud"', '"1"=>"az1-xyz09.centralus.azure.glb.priv.cpdev.cloud"', '', '', 'v-1', '{"PUBLIC"}', '{}', 'PUBLIC');

/* End Mothership State Seeding */
--
-- Name: kafka_quota; Type: TABLE; Schema: cc_control_plane_kafka; Owner: cc_control_plane_kafka
--
CREATE SCHEMA cc_control_plane_kafka;
CREATE TABLE cc_control_plane_kafka.kafka_quota (
  id character varying(32) NOT NULL PRIMARY KEY,
  lkc_id public.logical_cluster_id,
  pkc_id public.physical_cluster_id,
  org_id TEXT NOT NULL,
  env_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT NOT NULL,
  principals TEXT[] NOT NULL DEFAULT '{}',
  ingress_byte_rate BIGINT NOT NULL,
  egress_byte_rate BIGINT NOT NULL,
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  created_by TEXT NOT NULL,
  modified_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  modified_by TEXT NOT NULL,
  deactivated_at TIMESTAMP without TIME ZONE,
  last_change_id BIGINT NOT NULL default 1
);
CREATE INDEX kafka_quota_cluster_id ON cc_control_plane_kafka.kafka_quota (lkc_id);

CREATE SEQUENCE cc_control_plane_kafka.kafka_quotas_resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

/* Begin Secrets service seeding */

--
-- Name: cc_secrets; Type: SCHEMA; Schema: -; Owner: cc_scheduler_service
--

CREATE SCHEMA cc_secrets;

/* End Secrets service seeding */

--
-- Name: kafka_quota; Type: TABLE; Schema: cc_kafka_api_service; Owner: cc_kafka_api_service
--
CREATE SCHEMA cc_kafka_api_service;

CREATE TABLE cc_kafka_api_service.kafka_quota (
  id character varying(32) NOT NULL PRIMARY KEY,
  lkc_id public.logical_cluster_id,
  pkc_id public.physical_cluster_id,
  org_id TEXT NOT NULL,
  env_id TEXT NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT NOT NULL,
  principals TEXT[] NOT NULL DEFAULT '{}',
  ingress_byte_rate BIGINT NOT NULL,
  egress_byte_rate BIGINT NOT NULL,
  created_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  created_by TEXT NOT NULL,
  modified_at TIMESTAMP without TIME ZONE DEFAULT now() NOT NULL,
  modified_by TEXT NOT NULL,
  deactivated_at TIMESTAMP without TIME ZONE,
  last_change_id BIGINT NOT NULL default 1
);

CREATE INDEX kafka_quota_cluster_id ON cc_kafka_api_service.kafka_quota (lkc_id);

CREATE SEQUENCE cc_kafka_api_service.kafka_quotas_resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Grant table and sequence privileges

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_attribution_service permission
--

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_billing_worker permission
--

DO $$
BEGIN
  CREATE USER cc_billing_worker;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_billing_worker already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA deployment TO cc_billing_worker;

-- Tables owned by cc-billing-worker
GRANT ALL PRIVILEGES ON TABLE deployment.billing_invoice TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.billing_invoice_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.billing_job TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.billing_job_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.billing_order TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.billing_order_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.billing_record TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.credit TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.credit_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.price TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.price_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.price_audit_log TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.price_audit_log_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.promo_code TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.promo_code_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.promo_code_claim TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.promo_code_claim_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.task TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.task_id_seq TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.usage TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.usage_id_seq TO cc_billing_worker;

GRANT SELECT ON TABLE deployment.cdmum_dml_history TO cc_billing_worker;

-- Tables NOT owned by cc-billing-worker

GRANT ALL PRIVILEGES ON TABLE deployment.account TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.connect_plugin TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.deployment TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.k8s_cluster TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster_status TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster_status TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.network_region TO cc_billing_worker;
GRANT ALL PRIVILEGES ON TABLE deployment.organization TO cc_billing_worker;

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_cluster_upgrader permission
--

DO $$
BEGIN
  CREATE USER cc_cluster_upgrader;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_cluster_upgrader already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA control_plane TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.upgrade_request TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.upgrade_task TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.skip_upgrade_rules TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.policy TO cc_cluster_upgrader;

GRANT ALL PRIVILEGES ON TABLE control_plane.rollout_phase_execution TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.rollout TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.rollout_plan TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE control_plane.operation_type TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA control_plane TO cc_cluster_upgrader;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster TO cc_cluster_upgrader;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster_status TO cc_cluster_upgrader;

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_fleet_view permission
--

DO $$
BEGIN
  CREATE USER cc_fleet_view;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_fleet_view already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_fleet_view;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster TO cc_fleet_view;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster_status TO cc_fleet_view;

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_marketplace_service permission
--

DO $$
BEGIN
  CREATE USER cc_marketplace_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_marketplace_service already exists -- skip create';
END
$$;

GRANT ALL PRIVILEGES ON SCHEMA deployment TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON SCHEMA control_plane TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON SCHEMA public TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA deployment TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA control_plane TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA deployment TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA control_plane TO cc_marketplace_service;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cc_marketplace_service;

GRANT SELECT ON TABLE deployment.cdmum_dml_history TO cc_marketplace_service;

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_org_service permission
--

DO $$
BEGIN
  CREATE USER cc_org_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_org_service already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.account TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.account_num TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.event TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.event_id_seq TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.feature_opt_ins TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.feature_opt_ins_id_seq TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.feature_requests TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.org_membership TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.organization TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.organization_eventer_state TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.organization_id_seq TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.users TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.users_id_seq TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.users_resource_id_seq TO cc_org_service;
GRANT ALL PRIVILEGES ON TABLE deployment.invitations TO cc_org_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.invitations_id_seq TO cc_org_service;

GRANT ALL PRIVILEGES ON TABLE deployment.coupon TO cc_org_service;

GRANT INSERT ON TABLE deployment.cdmum_dml_history TO cc_org_service;
GRANT USAGE ON TABLE deployment.cdmum_dml_history_id_seq TO cc_org_service;

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_scheduler_service permission
--

DO $$
BEGIN
  CREATE USER cc_scheduler_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_scheduler_service already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA cc_secrets TO GROUP cc_scheduler_service;
GRANT ALL PRIVILEGES ON SCHEMA cc_secrets TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cc_secrets TO cc_scheduler_service;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_scheduler_service;
GRANT USAGE ON SCHEMA cc_capacity_service TO GROUP cc_scheduler_service;
GRANT ALL PRIVILEGES ON SCHEMA cc_capacity_service TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.k8s_cluster TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.physical_cluster TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.logical_cluster TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.constraints TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.network_info TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.region TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.zone TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE cc_capacity_service.realm TO cc_scheduler_service;

ALTER DOMAIN cc_capacity_service.k8s_cluster_id OWNER TO cc_scheduler_service;
ALTER DOMAIN cc_capacity_service.cloud_id OWNER TO cc_scheduler_service;
ALTER DOMAIN cc_capacity_service.region_id OWNER TO cc_scheduler_service;
ALTER DOMAIN cc_capacity_service.logical_cluster_id OWNER TO cc_scheduler_service;
ALTER DOMAIN cc_capacity_service.physical_cluster_id OWNER TO cc_scheduler_service;
ALTER DOMAIN cc_capacity_service.network_region_id OWNER TO cc_scheduler_service;
ALTER TYPE cc_capacity_service.cc_resource_type OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.k8s_cluster OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.logical_cluster OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.physical_cluster OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.network_info OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.constraints OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.region OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.zone OWNER TO cc_scheduler_service;
ALTER TABLE cc_capacity_service.realm OWNER TO cc_scheduler_service;

GRANT ALL PRIVILEGES ON TABLE deployment.connect_error_message_mappings TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.connect_plugin TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.connect_task_usage TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.deployment TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.k8s_cluster TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster_status TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.network_config TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.network_isolation_domain TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.network_region TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.physical_cluster_status TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.region TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.roll TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.secret TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.cert_registry TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.zone TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.realm TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.storage_class TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.environment TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.cloud TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.cloud_service_account TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.account TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.secret_physical_cluster_map TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.api_key_v2 TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.api_key_v2_internal_client TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.stream_governance_region TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.deployment_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.logical_cluster_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.network_config_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.network_isolation_domain_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.network_region_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.physical_cluster_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.storage_class_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.connect_error_message_mappings_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.connect_plugin_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.zone_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.secret_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.cert_registry_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.connect_task_usage_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.k8s_cluster_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.roll_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.api_key_v2_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.stream_governance_region_num TO cc_scheduler_service;

GRANT ALL PRIVILEGES ON TABLE deployment.users TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.users_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.users_resource_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.account TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.organization TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.organization_id_seq TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.account_num TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.cdmum_dml_history TO cc_scheduler_service;
GRANT ALL PRIVILEGES ON TABLE deployment.cdmum_dml_history_id_seq TO cc_scheduler_service;
------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_support_service permission
--

DO $$
BEGIN
  CREATE USER cc_support_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_support_service already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_support_service;
GRANT ALL PRIVILEGES ON TABLE deployment.support_plan_history TO cc_support_service;
GRANT ALL PRIVILEGES ON TABLE deployment.support_plan_history_id_seq TO cc_support_service;

CREATE SCHEMA IF NOT EXISTS billing;

ALTER SCHEMA billing OWNER TO caas;

CREATE TABLE billing.product_package (
                                         id SERIAL PRIMARY KEY,
                                         product_sku character varying(100) NOT NULL,
                                         product_name character varying(100) NOT NULL,
                                         package_sku character varying(100) NOT NULL,
                                         package_name character varying(100) NOT NULL,
                                         created timestamp without time zone DEFAULT now() NOT NULL,
                                         modified timestamp without time zone DEFAULT now() NOT NULL
);
CREATE INDEX IF NOT EXISTS product_package_product_sku ON billing.product_package (product_sku);
CREATE INDEX IF NOT EXISTS product_package_package_sku ON billing.product_package (package_sku);
CREATE UNIQUE INDEX IF NOT EXISTS product_package_product_package_sku ON billing.product_package (product_sku, package_sku);

ALTER TABLE billing.product_package OWNER TO caas;

CREATE TABLE billing.resource_package (
                                          id BIGSERIAL PRIMARY KEY,
                                          resource_type character varying(30) NOT NULL,
                                          resource_id character varying(128) NOT NULL,
                                          product_package_id integer NOT NULL,

                                          created timestamp without time zone DEFAULT now() NOT NULL,
                                          created_by character varying(60) NOT NULL,
                                          modified timestamp without time zone DEFAULT now() NOT NULL,
                                          modified_by character varying(60) NOT NULL,

                                          start_time timestamp without time zone DEFAULT now() NOT NULL,
                                          end_time timestamp without time zone,

                                          FOREIGN KEY (product_package_id) REFERENCES billing.product_package (id)
);
CREATE INDEX IF NOT EXISTS resource_package_type_id ON billing.resource_package (resource_type, resource_id);
CREATE INDEX IF NOT EXISTS resource_package_created ON billing.resource_package (created);
CREATE INDEX IF NOT EXISTS resource_package_modified ON billing.resource_package (modified);
CREATE INDEX IF NOT EXISTS resource_package_start_time ON billing.resource_package (start_time);
CREATE INDEX IF NOT EXISTS resource_package_end_time ON billing.resource_package (end_time);
CREATE INDEX IF NOT EXISTS resource_package_product_package_id ON billing.resource_package (product_package_id);

ALTER TABLE billing.resource_package OWNER TO caas;

CREATE TYPE billing.task_status AS ENUM ('running', 'succeeded', 'failed', 'ready');

CREATE TABLE billing.task (
                              id BIGSERIAL PRIMARY KEY,
                              organization_id integer,
                              created timestamp without time zone DEFAULT now() NOT NULL,
                              modified timestamp without time zone DEFAULT now() NOT NULL,
                              type text NOT NULL,
                              status billing.task_status NOT NULL,
                              from_time timestamp without time zone NOT NULL,
                              to_time timestamp without time zone NOT NULL,
                              error text
);

CREATE INDEX IF NOT EXISTS task_created_idx ON billing.task (created);

CREATE INDEX IF NOT EXISTS task_org_id_idx ON billing.task (organization_id);

CREATE INDEX IF NOT EXISTS task_type_idx ON billing.task (type);

CREATE INDEX IF NOT EXISTS task_from_time_idx ON billing.task (from_time);

CREATE INDEX IF NOT EXISTS task_to_time_idx ON billing.task (to_time);

ALTER TABLE billing.task OWNER TO caas;

GRANT USAGE ON SCHEMA billing TO GROUP cc_support_service;
GRANT ALL PRIVILEGES ON TABLE billing.product_package TO cc_support_service;
GRANT ALL PRIVILEGES ON SEQUENCE billing.product_package_id_seq TO cc_support_service;

GRANT ALL PRIVILEGES ON TABLE billing.resource_package TO cc_support_service;
GRANT ALL PRIVILEGES ON SEQUENCE billing.resource_package_id_seq TO cc_support_service;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA billing to cc_support_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA billing to cc_support_service;

insert into billing.product_package (product_sku, product_name, package_sku, package_name)
VALUES (LOWER('stream-governance'), 'Stream Governance', LOWER('free'), 'Stream Governance (Core)');

insert into billing.product_package (product_sku, product_name, package_sku, package_name)
VALUES (LOWER('stream-governance'), 'Stream Governance', LOWER('paid'), 'Stream Governance Advanced');

INSERT INTO deployment.promo_code
(code, amount, max_uses, code_validity_start_date, code_validity_end_date, credit_validity_days, is_enabled, created_by, modified_by)
VALUES ('SIGNUPPROMOCPD', 4000000, 10000, '2022-07-01 00:00:00', '2032-07-01 00:00:00', 60, true, 'test@confluent.io', 'test@confluent.io');

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_usage_feedback_connector permission
--

DO $$
BEGIN
  CREATE USER cc_usage_feedback_connector;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_usage_feedback_connector already exists -- skip create';
END
$$;

GRANT ALL PRIVILEGES ON SCHEMA deployment TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON SCHEMA control_plane TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON SCHEMA public TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA deployment TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA control_plane TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA deployment TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA control_plane TO cc_usage_feedback_connector;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cc_usage_feedback_connector;

------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_kafka_platform_manager permission
--

DO $$
BEGIN
  CREATE USER cc_kafka_platform_manager;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_kafka_platform_manager already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA kafka TO cc_kafka_platform_manager;
GRANT ALL PRIVILEGES ON TABLE kafka.rollout_plans TO cc_kafka_platform_manager;
GRANT ALL PRIVILEGES ON TABLE kafka.rollout_phases TO cc_kafka_platform_manager;
GRANT ALL PRIVILEGES ON TABLE kafka.rollout_clusters TO cc_kafka_platform_manager;
GRANT ALL PRIVILEGES ON TABLE kafka.rollout_heuristics TO cc_kafka_platform_manager;
GRANT ALL PRIVILEGES ON TABLE kafka.rollout_windows TO cc_kafka_platform_manager;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA kafka TO cc_kafka_platform_manager;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.k8s_cluster TO cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.physical_cluster TO cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.physical_cluster_status TO cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.logical_cluster TO cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.logical_cluster_status TO cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.organization TO cc_kafka_platform_manager;
GRANT SELECT ON TABLE deployment.account TO cc_kafka_platform_manager;

------------------------------------------------------------
------------------------------------------------------------

--
-- Role cc_networking_service permission
--
DO $$
BEGIN
  CREATE USER cc_networking_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_networking_service already exists -- skip create';
END
$$;

GRANT ALL PRIVILEGES ON SCHEMA public TO GROUP cc_networking_service;
GRANT ALL PRIVILEGES ON SCHEMA deployment TO GROUP cc_networking_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cc_networking_service;
GRANT SELECT ON ALL TABLES IN SCHEMA deployment TO cc_networking_service;
------------------------------------------------------------
------------------------------------------------------------

--
-- Role cc_control_plane_kafka permission
--

DO $$
BEGIN
  CREATE USER cc_control_plane_kafka;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_control_plane_kafka already exists -- skip create';
END
$$;

GRANT ALL PRIVILEGES ON SCHEMA cc_control_plane_kafka TO GROUP cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON SEQUENCE cc_control_plane_kafka.kafka_quotas_resource_id_seq TO GROUP cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cc_control_plane_kafka TO cc_control_plane_kafka;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster TO cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster_status TO cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.logical_cluster_num TO cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON TABLE deployment.deployment TO cc_control_plane_kafka;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.deployment_num TO cc_control_plane_kafka;

------------------------------------------------------------
------------------------------------------------------------

--
-- Role cc_kafka_api_service permission
--

DO $$
BEGIN
  CREATE USER cc_kafka_api_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_kafka_api_service already exists -- skip create';
END
$$;

GRANT ALL PRIVILEGES ON SCHEMA cc_kafka_api_service TO GROUP cc_kafka_api_service;
GRANT ALL PRIVILEGES ON SEQUENCE cc_kafka_api_service.kafka_quotas_resource_id_seq TO GROUP cc_kafka_api_service;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cc_kafka_api_service TO cc_kafka_api_service;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_kafka_api_service;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster TO cc_kafka_api_service;
GRANT ALL PRIVILEGES ON TABLE deployment.logical_cluster_status TO cc_kafka_api_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.logical_cluster_num TO cc_kafka_api_service;
GRANT ALL PRIVILEGES ON TABLE deployment.deployment TO cc_kafka_api_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.deployment_num TO cc_kafka_api_service;
------------------------------------------------------------
------------------------------------------------------------
--
-- Role cc_topology_service permission
--

DO $$
BEGIN
  CREATE USER cc_topology_service;
  EXCEPTION WHEN DUPLICATE_OBJECT THEN
  RAISE NOTICE 'user cc_topology_service already exists -- skip create';
END
$$;

GRANT USAGE ON SCHEMA deployment TO GROUP cc_topology_service;
GRANT ALL PRIVILEGES ON TABLE deployment.cloud TO cc_topology_service;
GRANT ALL PRIVILEGES ON TABLE deployment.region TO cc_topology_service;
GRANT ALL PRIVILEGES ON TABLE deployment.zone TO cc_topology_service;
GRANT ALL PRIVILEGES ON TABLE deployment.realm TO cc_topology_service;
GRANT ALL PRIVILEGES ON SEQUENCE deployment.zone_num TO cc_topology_service;

--
-- PostgreSQL database dump complete
--
