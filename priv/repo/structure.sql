--
-- PostgreSQL database dump
--

-- Dumped from database version 14.17 (Homebrew)
-- Dumped by pg_dump version 14.17 (Homebrew)

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
    updated_at timestamp(0) without time zone NOT NULL
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
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint,
    expires_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


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
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


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
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


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
-- Name: locations_slug_is_country_is_federal_state_is_county_is_city_is; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX locations_slug_is_country_is_federal_state_is_county_is_city_is ON public.locations USING btree (slug, is_country, is_federal_state, is_county, is_city, is_school);


--
-- Name: periods_holiday_or_vacation_type_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_holiday_or_vacation_type_id_index ON public.periods USING btree (holiday_or_vacation_type_id);


--
-- Name: periods_location_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_location_id_index ON public.periods USING btree (location_id);


--
-- Name: periods_religion_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periods_religion_id_index ON public.periods USING btree (religion_id);


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
