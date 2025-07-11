--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 14.18 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id bigint NOT NULL,
    line1 character varying(255),
    street character varying(255),
    zip_code character varying(255),
    city character varying(255),
    email_address character varying(255),
    phone_number character varying(255),
    fax_number character varying(255),
    homepage_url character varying(255),
    school_type character varying(255),
    official_id character varying(255),
    lon double precision,
    lat double precision,
    school_location_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    wikipedia_url character varying(255)
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: daily_change_counts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_change_counts (
    id bigint NOT NULL,
    date date NOT NULL,
    count integer DEFAULT 0 NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: daily_change_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_change_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_change_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_change_counts_id_seq OWNED BY public.daily_change_counts.id;


--
-- Name: deleted_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deleted_periods (
    id bigint NOT NULL,
    original_id integer NOT NULL,
    holiday_or_vacation_type_id integer,
    location_id integer,
    starts_on date,
    ends_on date,
    created_by_email_address character varying(255),
    html_class character varying(255),
    is_listed_below_month boolean DEFAULT false,
    is_public_holiday boolean DEFAULT false,
    is_school_vacation boolean DEFAULT false,
    is_valid_for_students boolean DEFAULT false,
    is_valid_for_everybody boolean DEFAULT false,
    memo text,
    display_priority integer DEFAULT 10,
    deleted_school_original_id integer NOT NULL,
    deleted_at timestamp(0) without time zone NOT NULL,
    deleted_by_user_id integer,
    original_inserted_at timestamp(0) without time zone,
    original_updated_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: deleted_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deleted_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deleted_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deleted_periods_id_seq OWNED BY public.deleted_periods.id;


--
-- Name: deleted_schools; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deleted_schools (
    id bigint NOT NULL,
    original_id integer NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255),
    code character varying(255),
    parent_location_id integer,
    cachable_calendar_location_id integer,
    is_country boolean DEFAULT false,
    is_federal_state boolean DEFAULT false,
    is_county boolean DEFAULT false,
    is_city boolean DEFAULT false,
    is_school boolean DEFAULT true,
    address_line1 character varying(255),
    address_street character varying(255),
    address_zip_code character varying(255),
    address_city character varying(255),
    address_email_address character varying(255),
    address_phone_number character varying(255),
    address_homepage_url character varying(255),
    address_school_type character varying(255),
    address_official_id character varying(255),
    address_lat double precision,
    address_lon double precision,
    deleted_at timestamp(0) without time zone NOT NULL,
    deleted_by_user_id integer,
    deletion_reason text,
    original_inserted_at timestamp(0) without time zone,
    original_updated_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: deleted_schools_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deleted_schools_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deleted_schools_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deleted_schools_id_seq OWNED BY public.deleted_schools.id;


--
-- Name: holiday_or_vacation_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holiday_or_vacation_types (
    id bigint NOT NULL,
    name character varying(255),
    colloquial character varying(255),
    slug character varying(255),
    default_html_class character varying(255),
    default_is_listed_below_month boolean DEFAULT false NOT NULL,
    default_is_public_holiday boolean DEFAULT false NOT NULL,
    default_is_school_vacation boolean DEFAULT false NOT NULL,
    default_is_valid_for_everybody boolean DEFAULT false NOT NULL,
    default_is_valid_for_students boolean DEFAULT false NOT NULL,
    wikipedia_url character varying(255),
    country_location_id bigint,
    default_religion_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    default_display_priority integer
);


--
-- Name: holiday_or_vacation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holiday_or_vacation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holiday_or_vacation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holiday_or_vacation_types_id_seq OWNED BY public.holiday_or_vacation_types.id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    id bigint NOT NULL,
    name character varying(255),
    slug character varying(255),
    code character varying(255),
    is_country boolean DEFAULT false NOT NULL,
    is_federal_state boolean DEFAULT false NOT NULL,
    is_county boolean DEFAULT false NOT NULL,
    is_city boolean DEFAULT false NOT NULL,
    is_school boolean DEFAULT false NOT NULL,
    parent_location_id bigint,
    cachable_calendar_location_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.id;


--
-- Name: periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periods (
    id bigint NOT NULL,
    starts_on date,
    ends_on date,
    created_by_email_address character varying(255),
    html_class character varying(255),
    is_listed_below_month boolean DEFAULT false NOT NULL,
    is_public_holiday boolean DEFAULT false NOT NULL,
    is_school_vacation boolean DEFAULT false NOT NULL,
    is_valid_for_everybody boolean DEFAULT false NOT NULL,
    is_valid_for_students boolean DEFAULT false NOT NULL,
    holiday_or_vacation_type_id bigint,
    location_id bigint,
    religion_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    memo text,
    display_priority integer,
    adjoining_duration integer,
    array_agg integer[]
);


--
-- Name: periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.periods_id_seq OWNED BY public.periods.id;


--
-- Name: religions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.religions (
    id bigint NOT NULL,
    name character varying(255),
    slug character varying(255),
    wikipedia_url character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: religions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.religions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: religions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.religions_id_seq OWNED BY public.religions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    event character varying(10) NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id integer,
    item_changes jsonb,
    originator_id integer,
    origin character varying(50),
    meta jsonb,
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: zip_code_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zip_code_mappings (
    id bigint NOT NULL,
    lat double precision,
    lon double precision,
    location_id bigint,
    zip_code_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: zip_code_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zip_code_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zip_code_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zip_code_mappings_id_seq OWNED BY public.zip_code_mappings.id;


--
-- Name: zip_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zip_codes (
    id bigint NOT NULL,
    value character varying(255),
    slug character varying(255),
    country_location_id bigint,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: zip_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zip_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zip_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zip_codes_id_seq OWNED BY public.zip_codes.id;


--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: daily_change_counts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_change_counts ALTER COLUMN id SET DEFAULT nextval('public.daily_change_counts_id_seq'::regclass);


--
-- Name: deleted_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_periods ALTER COLUMN id SET DEFAULT nextval('public.deleted_periods_id_seq'::regclass);


--
-- Name: deleted_schools id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_schools ALTER COLUMN id SET DEFAULT nextval('public.deleted_schools_id_seq'::regclass);


--
-- Name: holiday_or_vacation_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holiday_or_vacation_types ALTER COLUMN id SET DEFAULT nextval('public.holiday_or_vacation_types_id_seq'::regclass);


--
-- Name: locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- Name: periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods ALTER COLUMN id SET DEFAULT nextval('public.periods_id_seq'::regclass);


--
-- Name: religions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.religions ALTER COLUMN id SET DEFAULT nextval('public.religions_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: zip_code_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_code_mappings ALTER COLUMN id SET DEFAULT nextval('public.zip_code_mappings_id_seq'::regclass);


--
-- Name: zip_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_codes ALTER COLUMN id SET DEFAULT nextval('public.zip_codes_id_seq'::regclass);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: daily_change_counts daily_change_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_change_counts
    ADD CONSTRAINT daily_change_counts_pkey PRIMARY KEY (id);


--
-- Name: deleted_periods deleted_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_periods
    ADD CONSTRAINT deleted_periods_pkey PRIMARY KEY (id);


--
-- Name: deleted_schools deleted_schools_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deleted_schools
    ADD CONSTRAINT deleted_schools_pkey PRIMARY KEY (id);


--
-- Name: holiday_or_vacation_types holiday_or_vacation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holiday_or_vacation_types
    ADD CONSTRAINT holiday_or_vacation_types_pkey PRIMARY KEY (id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (id);


--
-- Name: periods periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_pkey PRIMARY KEY (id);


--
-- Name: religions religions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.religions
    ADD CONSTRAINT religions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: zip_code_mappings zip_code_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_code_mappings
    ADD CONSTRAINT zip_code_mappings_pkey PRIMARY KEY (id);


--
-- Name: zip_codes zip_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_codes
    ADD CONSTRAINT zip_codes_pkey PRIMARY KEY (id);


--
-- Name: addresses_school_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_school_location_id_index ON public.addresses USING btree (school_location_id);


--
-- Name: addresses_zip_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX addresses_zip_code_index ON public.addresses USING btree (zip_code);


--
-- Name: daily_change_counts_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX daily_change_counts_date_index ON public.daily_change_counts USING btree (date);


--
-- Name: deleted_periods_deleted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_periods_deleted_at_index ON public.deleted_periods USING btree (deleted_at);


--
-- Name: deleted_periods_deleted_school_original_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_periods_deleted_school_original_id_index ON public.deleted_periods USING btree (deleted_school_original_id);


--
-- Name: deleted_periods_original_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_periods_original_id_index ON public.deleted_periods USING btree (original_id);


--
-- Name: deleted_periods_starts_on_ends_on_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_periods_starts_on_ends_on_index ON public.deleted_periods USING btree (starts_on, ends_on);


--
-- Name: deleted_schools_deleted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_schools_deleted_at_index ON public.deleted_schools USING btree (deleted_at);


--
-- Name: deleted_schools_original_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_schools_original_id_index ON public.deleted_schools USING btree (original_id);


--
-- Name: deleted_schools_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX deleted_schools_slug_index ON public.deleted_schools USING btree (slug);


--
-- Name: holiday_or_vacation_types_country_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX holiday_or_vacation_types_country_location_id_index ON public.holiday_or_vacation_types USING btree (country_location_id);


--
-- Name: holiday_or_vacation_types_default_religion_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX holiday_or_vacation_types_default_religion_id_index ON public.holiday_or_vacation_types USING btree (default_religion_id);


--
-- Name: holiday_or_vacation_types_name_country_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX holiday_or_vacation_types_name_country_location_id_index ON public.holiday_or_vacation_types USING btree (name, country_location_id);


--
-- Name: holiday_or_vacation_types_slug_country_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX holiday_or_vacation_types_slug_country_location_id_index ON public.holiday_or_vacation_types USING btree (slug, country_location_id);


--
-- Name: locations_city_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_city_name_index ON public.locations USING btree (name) WHERE (is_city = true);


--
-- Name: locations_is_country_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_is_country_index ON public.locations USING btree (is_country) WHERE (is_country = true);


--
-- Name: locations_is_federal_state_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_is_federal_state_index ON public.locations USING btree (is_federal_state) WHERE (is_federal_state = true);


--
-- Name: locations_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_name_index ON public.locations USING btree (name);


--
-- Name: locations_parent_location_id_is_city_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_parent_location_id_is_city_index ON public.locations USING btree (parent_location_id, is_city);


--
-- Name: locations_parent_location_id_is_federal_state_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_parent_location_id_is_federal_state_index ON public.locations USING btree (parent_location_id, is_federal_state);


--
-- Name: locations_parent_location_id_is_school_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_parent_location_id_is_school_index ON public.locations USING btree (parent_location_id, is_school);


--
-- Name: locations_school_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_school_name_index ON public.locations USING btree (name) WHERE (is_school = true);


--
-- Name: locations_slug_is_city_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_slug_is_city_index ON public.locations USING btree (slug, is_city) WHERE (is_city = true);


--
-- Name: locations_slug_is_country_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_slug_is_country_index ON public.locations USING btree (slug, is_country) WHERE (is_country = true);


--
-- Name: locations_slug_is_country_is_federal_state_is_county_is_city_is; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX locations_slug_is_country_is_federal_state_is_county_is_city_is ON public.locations USING btree (slug, is_country, is_federal_state, is_county, is_city, is_school);


--
-- Name: locations_slug_is_federal_state_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_slug_is_federal_state_index ON public.locations USING btree (slug, is_federal_state) WHERE (is_federal_state = true);


--
-- Name: locations_slug_is_school_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX locations_slug_is_school_index ON public.locations USING btree (slug, is_school) WHERE (is_school = true);


--
-- Name: periods_holiday_or_vacation_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_holiday_or_vacation_type_id_index ON public.periods USING btree (holiday_or_vacation_type_id);


--
-- Name: periods_is_valid_for_students_is_valid_for_everybody_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_is_valid_for_students_is_valid_for_everybody_index ON public.periods USING btree (is_valid_for_students, is_valid_for_everybody);


--
-- Name: periods_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_location_id_index ON public.periods USING btree (location_id);


--
-- Name: periods_location_id_starts_on_ends_on_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_location_id_starts_on_ends_on_index ON public.periods USING btree (location_id, starts_on, ends_on);


--
-- Name: periods_religion_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_religion_id_index ON public.periods USING btree (religion_id);


--
-- Name: periods_starts_on_display_priority_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_starts_on_display_priority_index ON public.periods USING btree (starts_on, display_priority);


--
-- Name: periods_starts_on_ends_on_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_starts_on_ends_on_index ON public.periods USING btree (starts_on, ends_on);


--
-- Name: periods_starts_on_ends_on_location_id_holiday_or_vacation_type_; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX periods_starts_on_ends_on_location_id_holiday_or_vacation_type_ ON public.periods USING btree (starts_on, ends_on, location_id, holiday_or_vacation_type_id);


--
-- Name: religions_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX religions_name_index ON public.religions USING btree (name);


--
-- Name: religions_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX religions_slug_index ON public.religions USING btree (slug);


--
-- Name: versions_item_id_item_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_id_item_type_index ON public.versions USING btree (item_id, item_type);


--
-- Name: versions_originator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_originator_id_index ON public.versions USING btree (originator_id);


--
-- Name: zip_code_mappings_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX zip_code_mappings_location_id_index ON public.zip_code_mappings USING btree (location_id);


--
-- Name: zip_code_mappings_location_id_zip_code_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX zip_code_mappings_location_id_zip_code_id_index ON public.zip_code_mappings USING btree (location_id, zip_code_id);


--
-- Name: zip_code_mappings_zip_code_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX zip_code_mappings_zip_code_id_index ON public.zip_code_mappings USING btree (zip_code_id);


--
-- Name: zip_codes_country_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX zip_codes_country_location_id_index ON public.zip_codes USING btree (country_location_id);


--
-- Name: zip_codes_slug_country_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX zip_codes_slug_country_location_id_index ON public.zip_codes USING btree (slug, country_location_id);


--
-- Name: zip_codes_value_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX zip_codes_value_index ON public.zip_codes USING btree (value);


--
-- Name: addresses addresses_school_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_school_location_id_fkey FOREIGN KEY (school_location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: holiday_or_vacation_types holiday_or_vacation_types_country_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holiday_or_vacation_types
    ADD CONSTRAINT holiday_or_vacation_types_country_location_id_fkey FOREIGN KEY (country_location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: holiday_or_vacation_types holiday_or_vacation_types_default_religion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holiday_or_vacation_types
    ADD CONSTRAINT holiday_or_vacation_types_default_religion_id_fkey FOREIGN KEY (default_religion_id) REFERENCES public.religions(id) ON DELETE CASCADE;


--
-- Name: locations locations_cachable_calendar_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_cachable_calendar_location_id_fkey FOREIGN KEY (cachable_calendar_location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: locations locations_parent_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_parent_location_id_fkey FOREIGN KEY (parent_location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: periods periods_holiday_or_vacation_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_holiday_or_vacation_type_id_fkey FOREIGN KEY (holiday_or_vacation_type_id) REFERENCES public.holiday_or_vacation_types(id) ON DELETE CASCADE;


--
-- Name: periods periods_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: periods periods_religion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periods
    ADD CONSTRAINT periods_religion_id_fkey FOREIGN KEY (religion_id) REFERENCES public.religions(id) ON DELETE CASCADE;


--
-- Name: zip_code_mappings zip_code_mappings_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_code_mappings
    ADD CONSTRAINT zip_code_mappings_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- Name: zip_code_mappings zip_code_mappings_zip_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_code_mappings
    ADD CONSTRAINT zip_code_mappings_zip_code_id_fkey FOREIGN KEY (zip_code_id) REFERENCES public.zip_codes(id) ON DELETE CASCADE;


--
-- Name: zip_codes zip_codes_country_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zip_codes
    ADD CONSTRAINT zip_codes_country_location_id_fkey FOREIGN KEY (country_location_id) REFERENCES public.locations(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20200124142800);
INSERT INTO public."schema_migrations" (version) VALUES (20200126102003);
INSERT INTO public."schema_migrations" (version) VALUES (20200126102551);
INSERT INTO public."schema_migrations" (version) VALUES (20200128061258);
INSERT INTO public."schema_migrations" (version) VALUES (20200129143107);
INSERT INTO public."schema_migrations" (version) VALUES (20200129151006);
INSERT INTO public."schema_migrations" (version) VALUES (20200130131419);
INSERT INTO public."schema_migrations" (version) VALUES (20200201071737);
INSERT INTO public."schema_migrations" (version) VALUES (20200217052146);
INSERT INTO public."schema_migrations" (version) VALUES (20200312060652);
INSERT INTO public."schema_migrations" (version) VALUES (20200401043617);
INSERT INTO public."schema_migrations" (version) VALUES (20200401043619);
INSERT INTO public."schema_migrations" (version) VALUES (20240320000000);
INSERT INTO public."schema_migrations" (version) VALUES (20240321000000);
INSERT INTO public."schema_migrations" (version) VALUES (20240321000001);
INSERT INTO public."schema_migrations" (version) VALUES (20250605202926);
INSERT INTO public."schema_migrations" (version) VALUES (20250606070802);
INSERT INTO public."schema_migrations" (version) VALUES (20250606144035);
INSERT INTO public."schema_migrations" (version) VALUES (20250608165633);
INSERT INTO public."schema_migrations" (version) VALUES (20250623073245);
INSERT INTO public."schema_migrations" (version) VALUES (20250623145041);
INSERT INTO public."schema_migrations" (version) VALUES (20250626113823);
INSERT INTO public."schema_migrations" (version) VALUES (20250626113855);
INSERT INTO public."schema_migrations" (version) VALUES (20250626115814);
INSERT INTO public."schema_migrations" (version) VALUES (20250626120254);
