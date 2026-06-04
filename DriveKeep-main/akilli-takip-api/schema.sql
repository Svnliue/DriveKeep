--
-- PostgreSQL database dump
--

\restrict qpdMm0EbFfkbaHHTe8UiCnlrX9DdFE26e35L3yt09jY3AR6lrghADlEwJJ73hUu

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-06-05 01:52:52

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 32852)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 6009 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 669 (class 1255 OID 34074)
-- Name: kiralama_baslat_proseduru(integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.kiralama_baslat_proseduru(IN p_kullanici_id integer, IN p_arac_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- 1. İşlem: Kiralama tablosuna yeni kaydı ekle
    INSERT INTO kiralama (kullanici_id, arac_id, baslangic_zamani)
    VALUES (p_kullanici_id, p_arac_id, CURRENT_TIMESTAMP);

    -- 2. İşlem: Aracın durumunu 'pasif' (kullanimda) yap
    -- Not: Tablonda durum sütunu 'aktif'/'pasif' ise 'pasif' yapıyoruz
    UPDATE arac 
    SET durum = 'pasif' 
    WHERE arac_id = p_arac_id;

    -- Her şey tamamsa işlemleri kalıcı hale getir
    COMMIT;
    
    RAISE NOTICE 'Kiralama başarıyla başlatıldı ve araç durumu güncellendi.';
END;
$$;


ALTER PROCEDURE public.kiralama_baslat_proseduru(IN p_kullanici_id integer, IN p_arac_id integer) OWNER TO postgres;

--
-- TOC entry 537 (class 1255 OID 34075)
-- Name: kiralama_bitince_araci_boosa_cikar(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.kiralama_bitince_araci_boosa_cikar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Eğer kiralama tablosunda bitis_zamani güncellenirse (yani kiralama biterse)
    -- İlgili aracın durumunu otomatik olarak 'bos' yap.
    UPDATE public.arac 
    SET durum = 'bos' 
    WHERE arac_id = NEW.arac_id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.kiralama_bitince_araci_boosa_cikar() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 33963)
-- Name: arac; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.arac (
    arac_id integer NOT NULL,
    tur_id integer NOT NULL,
    fiyat_model_id integer NOT NULL,
    model character varying(50) NOT NULL,
    durum character varying(20) NOT NULL,
    batarya_seviyesi numeric(5,2),
    lat numeric(9,6),
    lng numeric(9,6)
);


ALTER TABLE public.arac OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 33978)
-- Name: fiyatlandirmamodelleri; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fiyatlandirmamodelleri (
    model_id integer NOT NULL,
    model_adi character varying(50) NOT NULL,
    acilis_ucreti numeric(10,2) NOT NULL,
    dakika_ucreti numeric(10,2) NOT NULL
);


ALTER TABLE public.fiyatlandirmamodelleri OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 33986)
-- Name: kiralama; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kiralama (
    kiralama_id bigint NOT NULL,
    arac_id integer NOT NULL,
    kullanici_id integer NOT NULL,
    baslangic_zamani timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    bitis_zamani timestamp with time zone,
    toplam_ucret numeric(10,2),
    CONSTRAINT kiralama_bitis_kontrol CHECK ((bitis_zamani >= baslangic_zamani))
);


ALTER TABLE public.kiralama OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 34005)
-- Name: kullanici; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kullanici (
    kullanici_id integer NOT NULL,
    ad_soyad character varying(100) NOT NULL,
    eposta character varying(100) NOT NULL,
    telefon character varying(20) NOT NULL
);


ALTER TABLE public.kullanici OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 34069)
-- Name: aktif_kiralama_ozet; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.aktif_kiralama_ozet AS
 SELECT k.kiralama_id,
    u.ad_soyad AS kiralayan_kullanici,
    a.arac_id,
    a.model AS kiralanan_arac,
    EXTRACT(epoch FROM (CURRENT_TIMESTAMP - k.baslangic_zamani)) AS sure_saniye,
    round((fm.acilis_ucreti + (ceil((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - k.baslangic_zamani)) / (60)::numeric)) * fm.dakika_ucreti)), 2) AS tahmini_fiyat
   FROM (((public.kiralama k
     JOIN public.kullanici u ON ((k.kullanici_id = u.kullanici_id)))
     JOIN public.arac a ON ((k.arac_id = a.arac_id)))
     JOIN public.fiyatlandirmamodelleri fm ON ((a.fiyat_model_id = fm.model_id)))
  WHERE (k.bitis_zamani IS NULL);


ALTER VIEW public.aktif_kiralama_ozet OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 33971)
-- Name: arac_arac_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.arac_arac_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.arac_arac_id_seq OWNER TO postgres;

--
-- TOC entry 6793 (class 0 OID 0)
-- Dependencies: 226
-- Name: arac_arac_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.arac_arac_id_seq OWNED BY public.arac.arac_id;


--
-- TOC entry 227 (class 1259 OID 33972)
-- Name: aracturu; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aracturu (
    tur_id integer NOT NULL,
    tur_adi character varying(50) NOT NULL
);


ALTER TABLE public.aracturu OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 33977)
-- Name: aracturu_tur_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aracturu_tur_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aracturu_tur_id_seq OWNER TO postgres;

--
-- TOC entry 6796 (class 0 OID 0)
-- Dependencies: 228
-- Name: aracturu_tur_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aracturu_tur_id_seq OWNED BY public.aracturu.tur_id;


--
-- TOC entry 230 (class 1259 OID 33985)
-- Name: fiyatlandirmamodelleri_model_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fiyatlandirmamodelleri_model_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fiyatlandirmamodelleri_model_id_seq OWNER TO postgres;

--
-- TOC entry 6798 (class 0 OID 0)
-- Dependencies: 230
-- Name: fiyatlandirmamodelleri_model_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fiyatlandirmamodelleri_model_id_seq OWNED BY public.fiyatlandirmamodelleri.model_id;


--
-- TOC entry 232 (class 1259 OID 33994)
-- Name: kiralama_kiralama_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kiralama_kiralama_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kiralama_kiralama_id_seq OWNER TO postgres;

--
-- TOC entry 6802 (class 0 OID 0)
-- Dependencies: 232
-- Name: kiralama_kiralama_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kiralama_kiralama_id_seq OWNED BY public.kiralama.kiralama_id;


--
-- TOC entry 233 (class 1259 OID 33995)
-- Name: konumtakip; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.konumtakip (
    kayit_id bigint NOT NULL,
    arac_id integer NOT NULL,
    zaman_damgasi timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    geometri public.geometry(Point,4326) NOT NULL
);


ALTER TABLE public.konumtakip OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 34004)
-- Name: konumtakip_kayit_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.konumtakip_kayit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.konumtakip_kayit_id_seq OWNER TO postgres;

--
-- TOC entry 6805 (class 0 OID 0)
-- Dependencies: 234
-- Name: konumtakip_kayit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.konumtakip_kayit_id_seq OWNED BY public.konumtakip.kayit_id;


--
-- TOC entry 236 (class 1259 OID 34012)
-- Name: kullanici_kullanici_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kullanici_kullanici_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kullanici_kullanici_id_seq OWNER TO postgres;

--
-- TOC entry 6807 (class 0 OID 0)
-- Dependencies: 236
-- Name: kullanici_kullanici_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kullanici_kullanici_id_seq OWNED BY public.kullanici.kullanici_id;


--
-- TOC entry 5801 (class 2604 OID 34013)
-- Name: arac arac_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arac ALTER COLUMN arac_id SET DEFAULT nextval('public.arac_arac_id_seq'::regclass);


--
-- TOC entry 5802 (class 2604 OID 34014)
-- Name: aracturu tur_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aracturu ALTER COLUMN tur_id SET DEFAULT nextval('public.aracturu_tur_id_seq'::regclass);


--
-- TOC entry 5803 (class 2604 OID 34015)
-- Name: fiyatlandirmamodelleri model_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fiyatlandirmamodelleri ALTER COLUMN model_id SET DEFAULT nextval('public.fiyatlandirmamodelleri_model_id_seq'::regclass);


--
-- TOC entry 5804 (class 2604 OID 34016)
-- Name: kiralama kiralama_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiralama ALTER COLUMN kiralama_id SET DEFAULT nextval('public.kiralama_kiralama_id_seq'::regclass);


--
-- TOC entry 5806 (class 2604 OID 34017)
-- Name: konumtakip kayit_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.konumtakip ALTER COLUMN kayit_id SET DEFAULT nextval('public.konumtakip_kayit_id_seq'::regclass);


--
-- TOC entry 5808 (class 2604 OID 34018)
-- Name: kullanici kullanici_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kullanici ALTER COLUMN kullanici_id SET DEFAULT nextval('public.kullanici_kullanici_id_seq'::regclass);


--
-- TOC entry 5991 (class 0 OID 33963)
-- Dependencies: 225
-- Data for Name: arac; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.arac (arac_id, tur_id, fiyat_model_id, model, durum, batarya_seviyesi, lat, lng) FROM stdin;
2	1	1	Gezgin (2)	kiralandi	30.20	40.658000	35.842000
4	2	2	ÇakılB (4)	bakim	\N	40.655000	35.825000
5	1	1	Kent (5)	kiralandi	78.00	40.660000	35.835000
6	1	1	Elektrik (6)	bos	15.00	40.655500	35.845500
7	1	1	Patika  (7)	kiralandi	88.90	40.649000	35.838000
8	1	1	Yolcu (8)	bakim	55.00	40.655500	35.825000
9	1	1	Çakıl (9)	bos	50.00	40.652000	35.829000
10	1	1	Gök Gürültüsü (10)	kiralandi	100.00	40.648000	35.848000
11	1	1	Sürücü (11)	kiralandi	45.00	40.651000	35.853000
13	2	2	SürücüB (13)	kiralandi	\N	40.652000	35.830500
14	2	2	ElektrikB  (14)	bos	\N	40.650500	35.850500
15	2	2	RüzgarB  (15)	bakim	\N	40.655000	35.825500
19	1	1	Sessiz (19)	bos	18.00	40.646400	35.807800
24	1	1	Vadi (24)	bos	12.00	40.660000	35.852000
1	1	1	Rüzgar (1)	pasif	95.50	40.655000	35.845000
18	1	1	Şimşek (18)	pasif	70.00	40.655000	35.828000
22	1	1	Savaşçı (22)	bos	40.00	40.658000	35.849000
16	1	1	Hızlı Rüzgar (16)	pasif	85.00	40.661700	35.802000
17	2	2	Yokuş Kralı (17)	pasif	\N	40.662500	35.805000
3	2	2	KentB (3)	pasif	\N	40.650000	35.850000
25	2	2	ŞehirB (25)	bos	\N	40.655000	35.858000
21	1	1	Köprü (21)	bos	90.00	40.645000	35.810000
23	2	2	MerkezB (23)	pasif	\N	40.658000	35.800000
20	2	2	Gönüllü (20)	pasif	\N	40.640000	35.844000
12	2	2	Yol Kralı (12)	bos	\N	40.645000	35.855000
\.


--
-- TOC entry 5993 (class 0 OID 33972)
-- Dependencies: 227
-- Data for Name: aracturu; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.aracturu (tur_id, tur_adi) FROM stdin;
1	Scooter
2	Bisiklet
\.


--
-- TOC entry 5995 (class 0 OID 33978)
-- Dependencies: 229
-- Data for Name: fiyatlandirmamodelleri; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fiyatlandirmamodelleri (model_id, model_adi, acilis_ucreti, dakika_ucreti) FROM stdin;
1	Standart Scooter Fiyatı	35.00	7.00
2	Premium Bisiklet Fiyatı	25.00	5.00
\.


--
-- TOC entry 5997 (class 0 OID 33986)
-- Dependencies: 231
-- Data for Name: kiralama; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kiralama (kiralama_id, arac_id, kullanici_id, baslangic_zamani, bitis_zamani, toplam_ucret) FROM stdin;
1	1	1	2025-12-09 10:00:00+03	2025-12-09 10:15:00+03	140.00
2	5	3	2025-12-05 14:30:00+03	2025-12-05 15:10:00+03	315.00
3	10	6	2025-12-01 09:00:00+03	2025-12-01 09:45:00+03	350.00
4	12	17	2025-11-28 18:00:00+03	2025-11-28 19:30:00+03	475.00
5	9	7	2025-11-25 11:30:00+03	2025-11-25 12:00:00+03	245.00
6	3	11	2025-11-22 20:00:00+03	2025-11-22 20:10:00+03	75.00
7	14	13	2025-11-20 16:15:00+03	2025-11-20 16:35:00+03	125.00
8	6	19	2025-11-18 07:45:00+03	2025-11-18 08:00:00+03	140.00
9	7	10	2025-11-15 13:00:00+03	2025-11-15 13:50:00+03	385.00
10	1	15	2025-11-13 09:00:00+03	2025-11-13 09:10:00+03	105.00
11	5	4	2025-11-11 17:00:00+03	2025-11-11 17:40:00+03	315.00
12	10	20	2025-11-10 12:00:00+03	2025-11-10 12:25:00+03	210.00
13	12	8	2025-12-08 10:30:00+03	2025-12-08 10:50:00+03	125.00
14	13	14	2025-12-07 15:00:00+03	2025-12-07 15:15:00+03	100.00
15	11	18	2025-12-06 19:00:00+03	2025-12-06 20:30:00+03	665.00
16	9	2	2025-12-04 11:00:00+03	2025-12-04 11:45:00+03	350.00
17	3	16	2025-12-03 09:30:00+03	2025-12-03 10:10:00+03	225.00
18	14	9	2025-12-02 07:00:00+03	2025-12-02 07:20:00+03	125.00
19	5	17	2025-12-01 10:30:00+03	2025-12-01 10:40:00+03	105.00
20	10	12	2025-11-12 23:00:00+03	2025-11-13 00:00:00+03	455.00
60	12	56	2026-01-18 00:49:56.457959+03	2026-01-18 02:25:23.245825+03	\N
37	13	17	2026-01-16 10:52:41.269186+03	2026-01-16 13:58:59.236974+03	\N
38	6	18	2026-01-16 10:52:41.269186+03	2026-01-16 14:03:09.532824+03	\N
39	18	5	2026-01-16 10:52:41.269186+03	2026-01-16 14:04:55.198588+03	\N
34	2	2	2026-01-16 10:52:41.269186+03	2026-01-16 14:05:33.061287+03	\N
35	7	12	2026-01-16 10:52:41.269186+03	2026-01-16 14:10:24.789061+03	\N
36	11	16	2026-01-16 10:52:41.269186+03	2026-01-16 14:16:49.486442+03	\N
40	20	10	2026-01-16 10:52:41.269186+03	2026-05-13 13:49:47.764737+03	\N
62	18	58	2026-01-18 00:58:43.829583+03	2026-05-13 13:50:48.576922+03	\N
64	1	60	2026-05-13 13:52:47.698508+03	2026-05-13 13:57:14.640028+03	\N
65	1	61	2026-05-14 00:21:52.392287+03	\N	\N
66	18	62	2026-05-14 00:23:33.223656+03	\N	\N
42	25	11	2026-01-16 10:52:41.269186+03	2026-05-14 00:23:41.584859+03	\N
61	3	57	2026-01-18 00:50:09.411322+03	2026-05-14 00:23:46.795295+03	\N
41	22	15	2026-01-16 10:52:41.269186+03	2026-05-14 00:27:44.789267+03	\N
70	16	66	2026-05-14 00:28:35.023781+03	\N	\N
71	17	67	2026-05-14 00:28:44.943011+03	\N	\N
72	3	68	2026-05-14 00:29:18.747029+03	\N	\N
73	20	69	2026-05-14 00:31:38.067959+03	2026-05-14 00:31:49.542165+03	\N
63	12	59	2026-05-13 13:46:27.747202+03	2026-05-14 11:10:51.4098+03	\N
68	23	64	2026-05-14 00:27:30.114119+03	2026-06-02 15:03:51.376415+03	\N
69	25	65	2026-05-14 00:28:03.550462+03	2026-06-02 15:07:37.544394+03	\N
75	20	71	2026-06-02 15:08:11.117218+03	2026-06-02 15:08:37.068068+03	\N
67	21	63	2026-05-14 00:27:14.812295+03	2026-06-02 15:11:38.767617+03	\N
76	23	72	2026-06-02 15:12:01.452569+03	\N	\N
77	20	73	2026-06-02 15:30:54.523729+03	\N	\N
74	12	70	2026-05-14 11:11:17.758753+03	2026-06-02 15:31:37.104148+03	\N
\.


--
-- TOC entry 5999 (class 0 OID 33995)
-- Dependencies: 233
-- Data for Name: konumtakip; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.konumtakip (kayit_id, arac_id, zaman_damgasi, geometri) FROM stdin;
16	16	2025-12-24 15:37:15.406122+03	0101000020E61000002DB29DEFA7E64140B1E1E995B2544440
17	17	2025-12-24 15:37:15.406122+03	0101000020E6100000D7A3703D0AE74140CDCCCCCCCC544440
18	19	2025-12-24 15:37:15.406122+03	0101000020E6100000BADA8AFD65E741403411363CBD524440
19	21	2025-12-24 15:37:15.406122+03	0101000020E610000048E17A14AEE74140C3F5285C8F524440
20	23	2025-12-24 15:37:15.406122+03	0101000020E61000006666666666E641404E62105839544440
26	16	2025-12-24 15:37:15.406122+03	0101000020E61000002DB29DEFA7E64140B1E1E995B2544440
27	17	2025-12-24 15:37:15.406122+03	0101000020E6100000D7A3703D0AE74140CDCCCCCCCC544440
28	19	2025-12-24 15:37:15.406122+03	0101000020E6100000BADA8AFD65E741403411363CBD524440
29	21	2025-12-24 15:37:15.406122+03	0101000020E610000048E17A14AEE74140C3F5285C8F524440
30	23	2025-12-24 15:37:15.406122+03	0101000020E61000006666666666E641404E62105839544440
31	16	2025-12-24 15:37:15.406122+03	0101000020E61000002DB29DEFA7E64140B1E1E995B2544440
32	17	2025-12-24 15:37:15.406122+03	0101000020E6100000D7A3703D0AE74140CDCCCCCCCC544440
33	19	2025-12-24 15:37:15.406122+03	0101000020E6100000BADA8AFD65E741403411363CBD524440
34	21	2025-12-24 15:37:15.406122+03	0101000020E610000048E17A14AEE74140C3F5285C8F524440
35	23	2025-12-24 15:37:15.406122+03	0101000020E61000006666666666E641404E62105839544440
1	1	2025-12-24 15:37:15.406122+03	0101000020E61000005C8FC2F528EC4140A4703D0AD7534440
2	3	2025-12-24 15:37:15.406122+03	0101000020E6100000CDCCCCCCCCEC41403333333333534440
3	5	2025-12-24 15:37:15.406122+03	0101000020E61000007B14AE47E1EA414014AE47E17A544440
6	10	2025-12-24 15:37:15.406122+03	0101000020E6100000068195438BEC41406DE7FBA9F1524440
7	12	2025-12-24 15:37:15.406122+03	0101000020E61000003D0AD7A370ED4140C3F5285C8F524440
9	2	2025-12-24 15:37:15.406122+03	0101000020E6100000B29DEFA7C6EB41404E62105839544440
10	7	2025-12-24 15:37:15.406122+03	0101000020E61000002506819543EB4140508D976E12534440
11	11	2025-12-24 15:37:15.406122+03	0101000020E610000077BE9F1A2FED414017D9CEF753534440
4	6	2025-12-24 15:37:15.406122+03	0101000020E61000004E62105839EC414096438B6CE7534440
8	14	2025-12-24 15:37:15.406122+03	0101000020E6100000BE9F1A2FDDEC41402506819543534440
21	24	2025-12-24 15:37:15.406122+03	0101000020E6100000931804560EED414014AE47E17A544440
22	18	2025-12-24 15:37:15.406122+03	0101000020E6100000448B6CE7FBE94140A4703D0AD7534440
23	20	2025-12-24 15:37:15.406122+03	0101000020E610000079E9263108EC414052B81E85EB514440
24	22	2025-12-24 15:37:15.406122+03	0101000020E6100000E9263108ACEC41404E62105839544440
25	25	2025-12-24 15:37:15.406122+03	0101000020E6100000E7FBA9F1D2ED4140A4703D0AD7534440
36	16	2025-12-24 15:37:15.406122+03	0101000020E61000002DB29DEFA7E64140B1E1E995B2544440
37	17	2025-12-24 15:37:15.406122+03	0101000020E6100000D7A3703D0AE74140CDCCCCCCCC544440
38	19	2025-12-24 15:37:15.406122+03	0101000020E6100000BADA8AFD65E741403411363CBD524440
39	21	2025-12-24 15:37:15.406122+03	0101000020E610000048E17A14AEE74140C3F5285C8F524440
40	23	2025-12-24 15:37:15.406122+03	0101000020E61000006666666666E641404E62105839544440
13	4	2025-12-24 15:37:15.406122+03	0101000020E61000009A99999999E94140A4703D0AD7534440
14	8	2025-12-24 15:37:15.406122+03	0101000020E61000009A99999999E9414096438B6CE7534440
15	15	2025-12-24 15:37:15.406122+03	0101000020E61000008B6CE7FBA9E94140A4703D0AD7534440
12	13	2025-12-24 15:37:15.406122+03	0101000020E6100000FCA9F1D24DEA4140FA7E6ABC74534440
5	9	2025-12-24 15:37:15.406122+03	0101000020E6100000273108AC1CEA4140FA7E6ABC74534440
\.


--
-- TOC entry 6001 (class 0 OID 34005)
-- Dependencies: 235
-- Data for Name: kullanici; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kullanici (kullanici_id, ad_soyad, eposta, telefon) FROM stdin;
1	Ayşe Yılmaz	ayse@mail.com	5551234567
2	Mehmet Öztürk	mehmet@mail.com	5559876543
3	Elif Kaya	elif.kaya@mail.com	5552010304
4	Burak Demir	burak.demir@mail.com	5553020405
5	Zeynep Çelik	zeynep.celik@mail.com	5554030506
6	Can Polat	can.polat@mail.com	5555040607
7	Deniz Arslan	deniz.arslan@mail.com	5556050708
8	Gizem Şahin	gizem.sahin@mail.com	5557060809
9	Hakan Aksoy	hakan.aksoy@mail.com	5558070910
10	İpek Kurt	ipek.kurt@mail.com	5559081011
11	Kerem Güneş	kerem.gunes@mail.com	5551191112
12	Leyla Tekin	leyla.tekin@mail.com	5551201213
13	Murat Yıldız	murat.yildiz@mail.com	5551311314
14	Nehir Doğan	nehir.dogan@mail.com	5551421415
15	Onur Erol	onur.erol@mail.com	5551531516
16	Pınar Kılıç	pinar.kilic@mail.com	5551641617
17	Rıza Koç	riza.koc@mail.com	5551751718
18	Seda Özer	seda.ozer@mail.com	5551861819
19	Tarık Erdem	tarik.erdem@mail.com	5551971920
20	Vildan Mert	vildan.mert@mail.com	5552082021
56	ss	ss@gmail.com	05559736336
57	akın demir 	akın@gmail.com	05559736339
58	Ss	akın@gmail.com@gmail.com	05515519736336
59	Can Demir	wqeqwe@gmail.com@gmail.com	05510222222222
60	Wqeqwwqe	wqeqw@icloud.com@gmail.com	05510141241421
61	Wewq Eqwe	ewqqw@gmail.com	05422222222
62	2434324	234234@gmail.com	02342343432
63	Eqweqw Wqeqwe	qweqweqw@hotmail.com	04332423423
64	Wqeqwqw	wqeqweq@hotmail.com	04343242344
65	Weqweq	qweqweqew@outlook.com	04314343243
66	Weqewqewq	qwqweqweqweqw@hotmail.com	01231231231
67	123123123	1321213@hotmail.com	01231131321
68	Weqweqweqw	qwewqwq@hotmail.com	03432432423
69	32112313133	2131231@gmail.com	03123121233
70	Eqweqwe	ewqe@outlook.com	05444444444
71	Muhammed	werewrewr@hotmail.com	04545353454
72	Erdem	wqeqwe@outlook.com	05343242342
73	Funda	weqwewqe@hotmail.com	04353453535
\.


--
-- TOC entry 5800 (class 0 OID 33171)
-- Dependencies: 221
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 6810 (class 0 OID 0)
-- Dependencies: 226
-- Name: arac_arac_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.arac_arac_id_seq', 25, true);


--
-- TOC entry 6811 (class 0 OID 0)
-- Dependencies: 228
-- Name: aracturu_tur_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aracturu_tur_id_seq', 3, true);


--
-- TOC entry 6812 (class 0 OID 0)
-- Dependencies: 230
-- Name: fiyatlandirmamodelleri_model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fiyatlandirmamodelleri_model_id_seq', 2, true);


--
-- TOC entry 6813 (class 0 OID 0)
-- Dependencies: 232
-- Name: kiralama_kiralama_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kiralama_kiralama_id_seq', 77, true);


--
-- TOC entry 6814 (class 0 OID 0)
-- Dependencies: 234
-- Name: konumtakip_kayit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.konumtakip_kayit_id_seq', 40, true);


--
-- TOC entry 6815 (class 0 OID 0)
-- Dependencies: 236
-- Name: kullanici_kullanici_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.kullanici_kullanici_id_seq', 73, true);


--
-- TOC entry 5814 (class 2606 OID 34020)
-- Name: arac arac_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arac
    ADD CONSTRAINT arac_pkey PRIMARY KEY (arac_id);


--
-- TOC entry 5816 (class 2606 OID 34022)
-- Name: aracturu aracturu_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aracturu
    ADD CONSTRAINT aracturu_pkey PRIMARY KEY (tur_id);


--
-- TOC entry 5818 (class 2606 OID 34024)
-- Name: aracturu aracturu_tur_adi_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aracturu
    ADD CONSTRAINT aracturu_tur_adi_key UNIQUE (tur_adi);


--
-- TOC entry 5820 (class 2606 OID 34026)
-- Name: fiyatlandirmamodelleri fiyatlandirmamodelleri_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fiyatlandirmamodelleri
    ADD CONSTRAINT fiyatlandirmamodelleri_pkey PRIMARY KEY (model_id);


--
-- TOC entry 5822 (class 2606 OID 34028)
-- Name: kiralama kiralama_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiralama
    ADD CONSTRAINT kiralama_pkey PRIMARY KEY (kiralama_id);


--
-- TOC entry 5825 (class 2606 OID 34030)
-- Name: konumtakip konumtakip_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.konumtakip
    ADD CONSTRAINT konumtakip_pkey PRIMARY KEY (kayit_id);


--
-- TOC entry 5827 (class 2606 OID 34032)
-- Name: kullanici kullanici_eposta_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kullanici
    ADD CONSTRAINT kullanici_eposta_key UNIQUE (eposta);


--
-- TOC entry 5829 (class 2606 OID 34034)
-- Name: kullanici kullanici_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kullanici
    ADD CONSTRAINT kullanici_pkey PRIMARY KEY (kullanici_id);


--
-- TOC entry 5831 (class 2606 OID 34036)
-- Name: kullanici kullanici_telefon_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kullanici
    ADD CONSTRAINT kullanici_telefon_key UNIQUE (telefon);


--
-- TOC entry 5823 (class 1259 OID 34037)
-- Name: idx_konumtakip_geometri; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_konumtakip_geometri ON public.konumtakip USING gist (geometri);


--
-- TOC entry 5837 (class 2620 OID 34076)
-- Name: kiralama trg_kiralama_sonlandir; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_kiralama_sonlandir AFTER UPDATE ON public.kiralama FOR EACH ROW WHEN (((old.bitis_zamani IS NULL) AND (new.bitis_zamani IS NOT NULL))) EXECUTE FUNCTION public.kiralama_bitince_araci_boosa_cikar();


--
-- TOC entry 5832 (class 2606 OID 34038)
-- Name: arac arac_fiyat_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arac
    ADD CONSTRAINT arac_fiyat_model_id_fkey FOREIGN KEY (fiyat_model_id) REFERENCES public.fiyatlandirmamodelleri(model_id);


--
-- TOC entry 5833 (class 2606 OID 34043)
-- Name: arac arac_tur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arac
    ADD CONSTRAINT arac_tur_id_fkey FOREIGN KEY (tur_id) REFERENCES public.aracturu(tur_id);


--
-- TOC entry 5834 (class 2606 OID 34048)
-- Name: kiralama kiralama_arac_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiralama
    ADD CONSTRAINT kiralama_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id);


--
-- TOC entry 5835 (class 2606 OID 34053)
-- Name: kiralama kiralama_kullanici_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kiralama
    ADD CONSTRAINT kiralama_kullanici_id_fkey FOREIGN KEY (kullanici_id) REFERENCES public.kullanici(kullanici_id);


--
-- TOC entry 5836 (class 2606 OID 34058)
-- Name: konumtakip konumtakip_arac_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.konumtakip
    ADD CONSTRAINT konumtakip_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id);


--
-- TOC entry 6008 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO drivekeep_app_user;


--
-- TOC entry 6010 (class 0 OID 0)
-- Dependencies: 646
-- Name: FUNCTION box2d_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d_in(cstring) TO drivekeep_app_user;


--
-- TOC entry 6011 (class 0 OID 0)
-- Dependencies: 727
-- Name: FUNCTION box2d_out(public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d_out(public.box2d) TO drivekeep_app_user;


--
-- TOC entry 6012 (class 0 OID 0)
-- Dependencies: 478
-- Name: FUNCTION box2df_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2df_in(cstring) TO drivekeep_app_user;


--
-- TOC entry 6013 (class 0 OID 0)
-- Dependencies: 546
-- Name: FUNCTION box2df_out(public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2df_out(public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6014 (class 0 OID 0)
-- Dependencies: 448
-- Name: FUNCTION box3d_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d_in(cstring) TO drivekeep_app_user;


--
-- TOC entry 6015 (class 0 OID 0)
-- Dependencies: 835
-- Name: FUNCTION box3d_out(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d_out(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6016 (class 0 OID 0)
-- Dependencies: 428
-- Name: FUNCTION geography_analyze(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_analyze(internal) TO drivekeep_app_user;


--
-- TOC entry 6017 (class 0 OID 0)
-- Dependencies: 424
-- Name: FUNCTION geography_in(cstring, oid, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_in(cstring, oid, integer) TO drivekeep_app_user;


--
-- TOC entry 6018 (class 0 OID 0)
-- Dependencies: 900
-- Name: FUNCTION geography_out(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_out(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6019 (class 0 OID 0)
-- Dependencies: 903
-- Name: FUNCTION geography_recv(internal, oid, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_recv(internal, oid, integer) TO drivekeep_app_user;


--
-- TOC entry 6020 (class 0 OID 0)
-- Dependencies: 653
-- Name: FUNCTION geography_send(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_send(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6021 (class 0 OID 0)
-- Dependencies: 893
-- Name: FUNCTION geography_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_typmod_in(cstring[]) TO drivekeep_app_user;


--
-- TOC entry 6022 (class 0 OID 0)
-- Dependencies: 410
-- Name: FUNCTION geography_typmod_out(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_typmod_out(integer) TO drivekeep_app_user;


--
-- TOC entry 6023 (class 0 OID 0)
-- Dependencies: 755
-- Name: FUNCTION geometry_analyze(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_analyze(internal) TO drivekeep_app_user;


--
-- TOC entry 6024 (class 0 OID 0)
-- Dependencies: 555
-- Name: FUNCTION geometry_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_in(cstring) TO drivekeep_app_user;


--
-- TOC entry 6025 (class 0 OID 0)
-- Dependencies: 577
-- Name: FUNCTION geometry_out(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_out(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6026 (class 0 OID 0)
-- Dependencies: 483
-- Name: FUNCTION geometry_recv(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_recv(internal) TO drivekeep_app_user;


--
-- TOC entry 6027 (class 0 OID 0)
-- Dependencies: 790
-- Name: FUNCTION geometry_send(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_send(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6028 (class 0 OID 0)
-- Dependencies: 929
-- Name: FUNCTION geometry_typmod_in(cstring[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_typmod_in(cstring[]) TO drivekeep_app_user;


--
-- TOC entry 6029 (class 0 OID 0)
-- Dependencies: 901
-- Name: FUNCTION geometry_typmod_out(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_typmod_out(integer) TO drivekeep_app_user;


--
-- TOC entry 6030 (class 0 OID 0)
-- Dependencies: 459
-- Name: FUNCTION gidx_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gidx_in(cstring) TO drivekeep_app_user;


--
-- TOC entry 6031 (class 0 OID 0)
-- Dependencies: 930
-- Name: FUNCTION gidx_out(public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gidx_out(public.gidx) TO drivekeep_app_user;


--
-- TOC entry 6032 (class 0 OID 0)
-- Dependencies: 758
-- Name: FUNCTION spheroid_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.spheroid_in(cstring) TO drivekeep_app_user;


--
-- TOC entry 6033 (class 0 OID 0)
-- Dependencies: 550
-- Name: FUNCTION spheroid_out(public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.spheroid_out(public.spheroid) TO drivekeep_app_user;


--
-- TOC entry 6034 (class 0 OID 0)
-- Dependencies: 707
-- Name: FUNCTION box3d(public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d(public.box2d) TO drivekeep_app_user;


--
-- TOC entry 6035 (class 0 OID 0)
-- Dependencies: 635
-- Name: FUNCTION geometry(public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.box2d) TO drivekeep_app_user;


--
-- TOC entry 6036 (class 0 OID 0)
-- Dependencies: 385
-- Name: FUNCTION box(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6037 (class 0 OID 0)
-- Dependencies: 348
-- Name: FUNCTION box2d(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6038 (class 0 OID 0)
-- Dependencies: 751
-- Name: FUNCTION geometry(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6039 (class 0 OID 0)
-- Dependencies: 638
-- Name: FUNCTION geography(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography(bytea) TO drivekeep_app_user;


--
-- TOC entry 6040 (class 0 OID 0)
-- Dependencies: 767
-- Name: FUNCTION geometry(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(bytea) TO drivekeep_app_user;


--
-- TOC entry 6041 (class 0 OID 0)
-- Dependencies: 678
-- Name: FUNCTION bytea(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.bytea(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6042 (class 0 OID 0)
-- Dependencies: 911
-- Name: FUNCTION geography(public.geography, integer, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography(public.geography, integer, boolean) TO drivekeep_app_user;


--
-- TOC entry 6043 (class 0 OID 0)
-- Dependencies: 458
-- Name: FUNCTION geometry(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6044 (class 0 OID 0)
-- Dependencies: 441
-- Name: FUNCTION box(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6045 (class 0 OID 0)
-- Dependencies: 952
-- Name: FUNCTION box2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box2d(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6046 (class 0 OID 0)
-- Dependencies: 689
-- Name: FUNCTION box3d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3d(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6047 (class 0 OID 0)
-- Dependencies: 941
-- Name: FUNCTION bytea(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.bytea(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6048 (class 0 OID 0)
-- Dependencies: 565
-- Name: FUNCTION geography(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6049 (class 0 OID 0)
-- Dependencies: 507
-- Name: FUNCTION geometry(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(public.geometry, integer, boolean) TO drivekeep_app_user;


--
-- TOC entry 6050 (class 0 OID 0)
-- Dependencies: 968
-- Name: FUNCTION "json"(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public."json"(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6051 (class 0 OID 0)
-- Dependencies: 871
-- Name: FUNCTION jsonb(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.jsonb(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6052 (class 0 OID 0)
-- Dependencies: 517
-- Name: FUNCTION path(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.path(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6053 (class 0 OID 0)
-- Dependencies: 405
-- Name: FUNCTION point(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.point(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6054 (class 0 OID 0)
-- Dependencies: 753
-- Name: FUNCTION polygon(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.polygon(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6055 (class 0 OID 0)
-- Dependencies: 523
-- Name: FUNCTION text(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.text(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6056 (class 0 OID 0)
-- Dependencies: 552
-- Name: FUNCTION geometry(path); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(path) TO drivekeep_app_user;


--
-- TOC entry 6057 (class 0 OID 0)
-- Dependencies: 650
-- Name: FUNCTION geometry(point); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(point) TO drivekeep_app_user;


--
-- TOC entry 6058 (class 0 OID 0)
-- Dependencies: 539
-- Name: FUNCTION geometry(polygon); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(polygon) TO drivekeep_app_user;


--
-- TOC entry 6059 (class 0 OID 0)
-- Dependencies: 676
-- Name: FUNCTION geometry(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry(text) TO drivekeep_app_user;


--
-- TOC entry 6060 (class 0 OID 0)
-- Dependencies: 985
-- Name: FUNCTION _postgis_deprecate(oldname text, newname text, version text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO drivekeep_app_user;


--
-- TOC entry 6061 (class 0 OID 0)
-- Dependencies: 966
-- Name: FUNCTION _postgis_index_extent(tbl regclass, col text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO drivekeep_app_user;


--
-- TOC entry 6062 (class 0 OID 0)
-- Dependencies: 416
-- Name: FUNCTION _postgis_join_selectivity(regclass, text, regclass, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO drivekeep_app_user;


--
-- TOC entry 6063 (class 0 OID 0)
-- Dependencies: 470
-- Name: FUNCTION _postgis_pgsql_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_pgsql_version() TO drivekeep_app_user;


--
-- TOC entry 6064 (class 0 OID 0)
-- Dependencies: 692
-- Name: FUNCTION _postgis_scripts_pgsql_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_scripts_pgsql_version() TO drivekeep_app_user;


--
-- TOC entry 6065 (class 0 OID 0)
-- Dependencies: 934
-- Name: FUNCTION _postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom public.geometry, mode text) TO drivekeep_app_user;


--
-- TOC entry 6066 (class 0 OID 0)
-- Dependencies: 715
-- Name: FUNCTION _postgis_stats(tbl regclass, att_name text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO drivekeep_app_user;


--
-- TOC entry 6067 (class 0 OID 0)
-- Dependencies: 811
-- Name: FUNCTION _st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6068 (class 0 OID 0)
-- Dependencies: 315
-- Name: FUNCTION _st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6069 (class 0 OID 0)
-- Dependencies: 388
-- Name: FUNCTION _st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6070 (class 0 OID 0)
-- Dependencies: 268
-- Name: FUNCTION _st_asgml(integer, public.geometry, integer, integer, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_asgml(integer, public.geometry, integer, integer, text, text) TO drivekeep_app_user;


--
-- TOC entry 6071 (class 0 OID 0)
-- Dependencies: 322
-- Name: FUNCTION _st_asx3d(integer, public.geometry, integer, integer, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_asx3d(integer, public.geometry, integer, integer, text) TO drivekeep_app_user;


--
-- TOC entry 6072 (class 0 OID 0)
-- Dependencies: 288
-- Name: FUNCTION _st_bestsrid(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6073 (class 0 OID 0)
-- Dependencies: 783
-- Name: FUNCTION _st_bestsrid(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_bestsrid(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6074 (class 0 OID 0)
-- Dependencies: 377
-- Name: FUNCTION _st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_contains(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6075 (class 0 OID 0)
-- Dependencies: 801
-- Name: FUNCTION _st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6076 (class 0 OID 0)
-- Dependencies: 314
-- Name: FUNCTION _st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_coveredby(geog1 public.geography, geog2 public.geography) TO drivekeep_app_user;


--
-- TOC entry 6077 (class 0 OID 0)
-- Dependencies: 244
-- Name: FUNCTION _st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_coveredby(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6078 (class 0 OID 0)
-- Dependencies: 313
-- Name: FUNCTION _st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_covers(geog1 public.geography, geog2 public.geography) TO drivekeep_app_user;


--
-- TOC entry 6079 (class 0 OID 0)
-- Dependencies: 730
-- Name: FUNCTION _st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_covers(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6080 (class 0 OID 0)
-- Dependencies: 915
-- Name: FUNCTION _st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_crosses(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6081 (class 0 OID 0)
-- Dependencies: 383
-- Name: FUNCTION _st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6082 (class 0 OID 0)
-- Dependencies: 445
-- Name: FUNCTION _st_distancetree(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6083 (class 0 OID 0)
-- Dependencies: 466
-- Name: FUNCTION _st_distancetree(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distancetree(public.geography, public.geography, double precision, boolean) TO drivekeep_app_user;


--
-- TOC entry 6084 (class 0 OID 0)
-- Dependencies: 489
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6085 (class 0 OID 0)
-- Dependencies: 665
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, boolean) TO drivekeep_app_user;


--
-- TOC entry 6086 (class 0 OID 0)
-- Dependencies: 344
-- Name: FUNCTION _st_distanceuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_distanceuncached(public.geography, public.geography, double precision, boolean) TO drivekeep_app_user;


--
-- TOC entry 6087 (class 0 OID 0)
-- Dependencies: 395
-- Name: FUNCTION _st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6088 (class 0 OID 0)
-- Dependencies: 399
-- Name: FUNCTION _st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6089 (class 0 OID 0)
-- Dependencies: 371
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision) TO drivekeep_app_user;


--
-- TOC entry 6090 (class 0 OID 0)
-- Dependencies: 951
-- Name: FUNCTION _st_dwithinuncached(public.geography, public.geography, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_dwithinuncached(public.geography, public.geography, double precision, boolean) TO drivekeep_app_user;


--
-- TOC entry 6091 (class 0 OID 0)
-- Dependencies: 637
-- Name: FUNCTION _st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_equals(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6092 (class 0 OID 0)
-- Dependencies: 855
-- Name: FUNCTION _st_expand(public.geography, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_expand(public.geography, double precision) TO drivekeep_app_user;


--
-- TOC entry 6093 (class 0 OID 0)
-- Dependencies: 261
-- Name: FUNCTION _st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_geomfromgml(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6094 (class 0 OID 0)
-- Dependencies: 686
-- Name: FUNCTION _st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_intersects(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6095 (class 0 OID 0)
-- Dependencies: 503
-- Name: FUNCTION _st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6096 (class 0 OID 0)
-- Dependencies: 264
-- Name: FUNCTION _st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_longestline(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6097 (class 0 OID 0)
-- Dependencies: 454
-- Name: FUNCTION _st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6098 (class 0 OID 0)
-- Dependencies: 670
-- Name: FUNCTION _st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6099 (class 0 OID 0)
-- Dependencies: 817
-- Name: FUNCTION _st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_overlaps(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6100 (class 0 OID 0)
-- Dependencies: 631
-- Name: FUNCTION _st_pointoutside(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_pointoutside(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6101 (class 0 OID 0)
-- Dependencies: 732
-- Name: FUNCTION _st_sortablehash(geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_sortablehash(geom public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6102 (class 0 OID 0)
-- Dependencies: 617
-- Name: FUNCTION _st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_touches(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6103 (class 0 OID 0)
-- Dependencies: 570
-- Name: FUNCTION _st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_voronoi(g1 public.geometry, clip public.geometry, tolerance double precision, return_polygons boolean) TO drivekeep_app_user;


--
-- TOC entry 6104 (class 0 OID 0)
-- Dependencies: 262
-- Name: FUNCTION _st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public._st_within(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6105 (class 0 OID 0)
-- Dependencies: 953
-- Name: FUNCTION addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO drivekeep_app_user;


--
-- TOC entry 6106 (class 0 OID 0)
-- Dependencies: 739
-- Name: FUNCTION addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO drivekeep_app_user;


--
-- TOC entry 6107 (class 0 OID 0)
-- Dependencies: 774
-- Name: FUNCTION addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO drivekeep_app_user;


--
-- TOC entry 6108 (class 0 OID 0)
-- Dependencies: 446
-- Name: FUNCTION box3dtobox(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.box3dtobox(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6109 (class 0 OID 0)
-- Dependencies: 561
-- Name: FUNCTION contains_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6110 (class 0 OID 0)
-- Dependencies: 844
-- Name: FUNCTION contains_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.contains_2d(public.box2df, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6111 (class 0 OID 0)
-- Dependencies: 651
-- Name: FUNCTION contains_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.contains_2d(public.geometry, public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6112 (class 0 OID 0)
-- Dependencies: 762
-- Name: FUNCTION dropgeometrycolumn(table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO drivekeep_app_user;


--
-- TOC entry 6113 (class 0 OID 0)
-- Dependencies: 267
-- Name: FUNCTION dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO drivekeep_app_user;


--
-- TOC entry 6114 (class 0 OID 0)
-- Dependencies: 621
-- Name: FUNCTION dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO drivekeep_app_user;


--
-- TOC entry 6115 (class 0 OID 0)
-- Dependencies: 475
-- Name: FUNCTION dropgeometrytable(table_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrytable(table_name character varying) TO drivekeep_app_user;


--
-- TOC entry 6116 (class 0 OID 0)
-- Dependencies: 882
-- Name: FUNCTION dropgeometrytable(schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO drivekeep_app_user;


--
-- TOC entry 6117 (class 0 OID 0)
-- Dependencies: 842
-- Name: FUNCTION dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO drivekeep_app_user;


--
-- TOC entry 6118 (class 0 OID 0)
-- Dependencies: 406
-- Name: FUNCTION equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.equals(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6119 (class 0 OID 0)
-- Dependencies: 795
-- Name: FUNCTION find_srid(character varying, character varying, character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.find_srid(character varying, character varying, character varying) TO drivekeep_app_user;


--
-- TOC entry 6120 (class 0 OID 0)
-- Dependencies: 335
-- Name: FUNCTION geog_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6121 (class 0 OID 0)
-- Dependencies: 536
-- Name: FUNCTION geog_brin_inclusion_merge(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geog_brin_inclusion_merge(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6122 (class 0 OID 0)
-- Dependencies: 356
-- Name: FUNCTION geography_cmp(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_cmp(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6123 (class 0 OID 0)
-- Dependencies: 279
-- Name: FUNCTION geography_distance_knn(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_distance_knn(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6124 (class 0 OID 0)
-- Dependencies: 293
-- Name: FUNCTION geography_eq(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_eq(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6125 (class 0 OID 0)
-- Dependencies: 613
-- Name: FUNCTION geography_ge(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_ge(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6126 (class 0 OID 0)
-- Dependencies: 782
-- Name: FUNCTION geography_gist_compress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_compress(internal) TO drivekeep_app_user;


--
-- TOC entry 6127 (class 0 OID 0)
-- Dependencies: 438
-- Name: FUNCTION geography_gist_consistent(internal, public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_consistent(internal, public.geography, integer) TO drivekeep_app_user;


--
-- TOC entry 6128 (class 0 OID 0)
-- Dependencies: 360
-- Name: FUNCTION geography_gist_decompress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_decompress(internal) TO drivekeep_app_user;


--
-- TOC entry 6129 (class 0 OID 0)
-- Dependencies: 856
-- Name: FUNCTION geography_gist_distance(internal, public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_distance(internal, public.geography, integer) TO drivekeep_app_user;


--
-- TOC entry 6130 (class 0 OID 0)
-- Dependencies: 238
-- Name: FUNCTION geography_gist_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6131 (class 0 OID 0)
-- Dependencies: 349
-- Name: FUNCTION geography_gist_picksplit(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_picksplit(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6132 (class 0 OID 0)
-- Dependencies: 594
-- Name: FUNCTION geography_gist_same(public.box2d, public.box2d, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_same(public.box2d, public.box2d, internal) TO drivekeep_app_user;


--
-- TOC entry 6133 (class 0 OID 0)
-- Dependencies: 256
-- Name: FUNCTION geography_gist_union(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gist_union(bytea, internal) TO drivekeep_app_user;


--
-- TOC entry 6134 (class 0 OID 0)
-- Dependencies: 737
-- Name: FUNCTION geography_gt(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_gt(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6135 (class 0 OID 0)
-- Dependencies: 960
-- Name: FUNCTION geography_le(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_le(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6136 (class 0 OID 0)
-- Dependencies: 412
-- Name: FUNCTION geography_lt(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_lt(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6137 (class 0 OID 0)
-- Dependencies: 354
-- Name: FUNCTION geography_overlaps(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_overlaps(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6138 (class 0 OID 0)
-- Dependencies: 796
-- Name: FUNCTION geography_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6139 (class 0 OID 0)
-- Dependencies: 813
-- Name: FUNCTION geography_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_compress_nd(internal) TO drivekeep_app_user;


--
-- TOC entry 6140 (class 0 OID 0)
-- Dependencies: 527
-- Name: FUNCTION geography_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6141 (class 0 OID 0)
-- Dependencies: 307
-- Name: FUNCTION geography_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6142 (class 0 OID 0)
-- Dependencies: 745
-- Name: FUNCTION geography_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6143 (class 0 OID 0)
-- Dependencies: 969
-- Name: FUNCTION geography_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6144 (class 0 OID 0)
-- Dependencies: 368
-- Name: FUNCTION geom2d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6145 (class 0 OID 0)
-- Dependencies: 659
-- Name: FUNCTION geom2d_brin_inclusion_merge(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom2d_brin_inclusion_merge(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6146 (class 0 OID 0)
-- Dependencies: 627
-- Name: FUNCTION geom3d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6147 (class 0 OID 0)
-- Dependencies: 316
-- Name: FUNCTION geom3d_brin_inclusion_merge(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom3d_brin_inclusion_merge(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6148 (class 0 OID 0)
-- Dependencies: 254
-- Name: FUNCTION geom4d_brin_inclusion_add_value(internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6149 (class 0 OID 0)
-- Dependencies: 948
-- Name: FUNCTION geom4d_brin_inclusion_merge(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geom4d_brin_inclusion_merge(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6150 (class 0 OID 0)
-- Dependencies: 447
-- Name: FUNCTION geometry_above(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_above(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6151 (class 0 OID 0)
-- Dependencies: 662
-- Name: FUNCTION geometry_below(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_below(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6152 (class 0 OID 0)
-- Dependencies: 931
-- Name: FUNCTION geometry_cmp(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_cmp(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6153 (class 0 OID 0)
-- Dependencies: 877
-- Name: FUNCTION geometry_contained_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contained_3d(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6154 (class 0 OID 0)
-- Dependencies: 554
-- Name: FUNCTION geometry_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contains(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6155 (class 0 OID 0)
-- Dependencies: 553
-- Name: FUNCTION geometry_contains_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contains_3d(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6156 (class 0 OID 0)
-- Dependencies: 862
-- Name: FUNCTION geometry_contains_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_contains_nd(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6157 (class 0 OID 0)
-- Dependencies: 816
-- Name: FUNCTION geometry_distance_box(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_box(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6158 (class 0 OID 0)
-- Dependencies: 988
-- Name: FUNCTION geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6159 (class 0 OID 0)
-- Dependencies: 535
-- Name: FUNCTION geometry_distance_centroid_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_centroid_nd(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6160 (class 0 OID 0)
-- Dependencies: 538
-- Name: FUNCTION geometry_distance_cpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_distance_cpa(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6161 (class 0 OID 0)
-- Dependencies: 404
-- Name: FUNCTION geometry_eq(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_eq(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6162 (class 0 OID 0)
-- Dependencies: 921
-- Name: FUNCTION geometry_ge(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_ge(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6163 (class 0 OID 0)
-- Dependencies: 742
-- Name: FUNCTION geometry_gist_compress_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_2d(internal) TO drivekeep_app_user;


--
-- TOC entry 6164 (class 0 OID 0)
-- Dependencies: 1000
-- Name: FUNCTION geometry_gist_compress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_compress_nd(internal) TO drivekeep_app_user;


--
-- TOC entry 6165 (class 0 OID 0)
-- Dependencies: 919
-- Name: FUNCTION geometry_gist_consistent_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_2d(internal, public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6166 (class 0 OID 0)
-- Dependencies: 241
-- Name: FUNCTION geometry_gist_consistent_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_consistent_nd(internal, public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6167 (class 0 OID 0)
-- Dependencies: 415
-- Name: FUNCTION geometry_gist_decompress_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_2d(internal) TO drivekeep_app_user;


--
-- TOC entry 6168 (class 0 OID 0)
-- Dependencies: 887
-- Name: FUNCTION geometry_gist_decompress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_decompress_nd(internal) TO drivekeep_app_user;


--
-- TOC entry 6169 (class 0 OID 0)
-- Dependencies: 361
-- Name: FUNCTION geometry_gist_distance_2d(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_2d(internal, public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6170 (class 0 OID 0)
-- Dependencies: 765
-- Name: FUNCTION geometry_gist_distance_nd(internal, public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_distance_nd(internal, public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6171 (class 0 OID 0)
-- Dependencies: 773
-- Name: FUNCTION geometry_gist_penalty_2d(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6172 (class 0 OID 0)
-- Dependencies: 685
-- Name: FUNCTION geometry_gist_penalty_nd(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6173 (class 0 OID 0)
-- Dependencies: 298
-- Name: FUNCTION geometry_gist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6174 (class 0 OID 0)
-- Dependencies: 557
-- Name: FUNCTION geometry_gist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6175 (class 0 OID 0)
-- Dependencies: 616
-- Name: FUNCTION geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_same_2d(geom1 public.geometry, geom2 public.geometry, internal) TO drivekeep_app_user;


--
-- TOC entry 6176 (class 0 OID 0)
-- Dependencies: 857
-- Name: FUNCTION geometry_gist_same_nd(public.geometry, public.geometry, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_same_nd(public.geometry, public.geometry, internal) TO drivekeep_app_user;


--
-- TOC entry 6177 (class 0 OID 0)
-- Dependencies: 287
-- Name: FUNCTION geometry_gist_sortsupport_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO drivekeep_app_user;


--
-- TOC entry 6178 (class 0 OID 0)
-- Dependencies: 793
-- Name: FUNCTION geometry_gist_union_2d(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO drivekeep_app_user;


--
-- TOC entry 6179 (class 0 OID 0)
-- Dependencies: 962
-- Name: FUNCTION geometry_gist_union_nd(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO drivekeep_app_user;


--
-- TOC entry 6180 (class 0 OID 0)
-- Dependencies: 938
-- Name: FUNCTION geometry_gt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_gt(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6181 (class 0 OID 0)
-- Dependencies: 276
-- Name: FUNCTION geometry_hash(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_hash(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6182 (class 0 OID 0)
-- Dependencies: 729
-- Name: FUNCTION geometry_le(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_le(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6183 (class 0 OID 0)
-- Dependencies: 433
-- Name: FUNCTION geometry_left(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_left(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6184 (class 0 OID 0)
-- Dependencies: 559
-- Name: FUNCTION geometry_lt(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_lt(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6185 (class 0 OID 0)
-- Dependencies: 304
-- Name: FUNCTION geometry_neq(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_neq(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6186 (class 0 OID 0)
-- Dependencies: 690
-- Name: FUNCTION geometry_overabove(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overabove(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6187 (class 0 OID 0)
-- Dependencies: 436
-- Name: FUNCTION geometry_overbelow(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overbelow(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6188 (class 0 OID 0)
-- Dependencies: 858
-- Name: FUNCTION geometry_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overlaps(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6189 (class 0 OID 0)
-- Dependencies: 255
-- Name: FUNCTION geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overlaps_3d(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6190 (class 0 OID 0)
-- Dependencies: 474
-- Name: FUNCTION geometry_overlaps_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overlaps_nd(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6191 (class 0 OID 0)
-- Dependencies: 973
-- Name: FUNCTION geometry_overleft(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overleft(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6192 (class 0 OID 0)
-- Dependencies: 725
-- Name: FUNCTION geometry_overright(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_overright(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6193 (class 0 OID 0)
-- Dependencies: 257
-- Name: FUNCTION geometry_right(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_right(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6194 (class 0 OID 0)
-- Dependencies: 967
-- Name: FUNCTION geometry_same(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_same(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6195 (class 0 OID 0)
-- Dependencies: 614
-- Name: FUNCTION geometry_same_3d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_same_3d(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6196 (class 0 OID 0)
-- Dependencies: 823
-- Name: FUNCTION geometry_same_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_same_nd(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6197 (class 0 OID 0)
-- Dependencies: 928
-- Name: FUNCTION geometry_sortsupport(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_sortsupport(internal) TO drivekeep_app_user;


--
-- TOC entry 6198 (class 0 OID 0)
-- Dependencies: 622
-- Name: FUNCTION geometry_spgist_choose_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6199 (class 0 OID 0)
-- Dependencies: 1001
-- Name: FUNCTION geometry_spgist_choose_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6200 (class 0 OID 0)
-- Dependencies: 996
-- Name: FUNCTION geometry_spgist_choose_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6201 (class 0 OID 0)
-- Dependencies: 387
-- Name: FUNCTION geometry_spgist_compress_2d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_2d(internal) TO drivekeep_app_user;


--
-- TOC entry 6202 (class 0 OID 0)
-- Dependencies: 530
-- Name: FUNCTION geometry_spgist_compress_3d(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_3d(internal) TO drivekeep_app_user;


--
-- TOC entry 6203 (class 0 OID 0)
-- Dependencies: 246
-- Name: FUNCTION geometry_spgist_compress_nd(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_compress_nd(internal) TO drivekeep_app_user;


--
-- TOC entry 6204 (class 0 OID 0)
-- Dependencies: 913
-- Name: FUNCTION geometry_spgist_config_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6205 (class 0 OID 0)
-- Dependencies: 587
-- Name: FUNCTION geometry_spgist_config_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6206 (class 0 OID 0)
-- Dependencies: 716
-- Name: FUNCTION geometry_spgist_config_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6207 (class 0 OID 0)
-- Dependencies: 263
-- Name: FUNCTION geometry_spgist_inner_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6208 (class 0 OID 0)
-- Dependencies: 677
-- Name: FUNCTION geometry_spgist_inner_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6209 (class 0 OID 0)
-- Dependencies: 687
-- Name: FUNCTION geometry_spgist_inner_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6210 (class 0 OID 0)
-- Dependencies: 571
-- Name: FUNCTION geometry_spgist_leaf_consistent_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6211 (class 0 OID 0)
-- Dependencies: 754
-- Name: FUNCTION geometry_spgist_leaf_consistent_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6212 (class 0 OID 0)
-- Dependencies: 504
-- Name: FUNCTION geometry_spgist_leaf_consistent_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6213 (class 0 OID 0)
-- Dependencies: 434
-- Name: FUNCTION geometry_spgist_picksplit_2d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6214 (class 0 OID 0)
-- Dependencies: 878
-- Name: FUNCTION geometry_spgist_picksplit_3d(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6215 (class 0 OID 0)
-- Dependencies: 625
-- Name: FUNCTION geometry_spgist_picksplit_nd(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6216 (class 0 OID 0)
-- Dependencies: 926
-- Name: FUNCTION geometry_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_within(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6217 (class 0 OID 0)
-- Dependencies: 400
-- Name: FUNCTION geometry_within_nd(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometry_within_nd(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6218 (class 0 OID 0)
-- Dependencies: 763
-- Name: FUNCTION geometrytype(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometrytype(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6219 (class 0 OID 0)
-- Dependencies: 846
-- Name: FUNCTION geometrytype(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geometrytype(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6220 (class 0 OID 0)
-- Dependencies: 455
-- Name: FUNCTION geomfromewkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geomfromewkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6221 (class 0 OID 0)
-- Dependencies: 624
-- Name: FUNCTION geomfromewkt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.geomfromewkt(text) TO drivekeep_app_user;


--
-- TOC entry 6222 (class 0 OID 0)
-- Dependencies: 397
-- Name: FUNCTION get_proj4_from_srid(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_proj4_from_srid(integer) TO drivekeep_app_user;


--
-- TOC entry 6223 (class 0 OID 0)
-- Dependencies: 494
-- Name: FUNCTION gserialized_gist_joinsel_2d(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO drivekeep_app_user;


--
-- TOC entry 6224 (class 0 OID 0)
-- Dependencies: 955
-- Name: FUNCTION gserialized_gist_joinsel_nd(internal, oid, internal, smallint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO drivekeep_app_user;


--
-- TOC entry 6225 (class 0 OID 0)
-- Dependencies: 340
-- Name: FUNCTION gserialized_gist_sel_2d(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO drivekeep_app_user;


--
-- TOC entry 6226 (class 0 OID 0)
-- Dependencies: 909
-- Name: FUNCTION gserialized_gist_sel_nd(internal, oid, internal, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO drivekeep_app_user;


--
-- TOC entry 6227 (class 0 OID 0)
-- Dependencies: 533
-- Name: FUNCTION is_contained_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6228 (class 0 OID 0)
-- Dependencies: 579
-- Name: FUNCTION is_contained_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.box2df, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6229 (class 0 OID 0)
-- Dependencies: 421
-- Name: FUNCTION is_contained_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_contained_2d(public.geometry, public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6230 (class 0 OID 0)
-- Dependencies: 669
-- Name: PROCEDURE kiralama_baslat_proseduru(IN p_kullanici_id integer, IN p_arac_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON PROCEDURE public.kiralama_baslat_proseduru(IN p_kullanici_id integer, IN p_arac_id integer) TO drivekeep_app_user;


--
-- TOC entry 6231 (class 0 OID 0)
-- Dependencies: 537
-- Name: FUNCTION kiralama_bitince_araci_boosa_cikar(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.kiralama_bitince_araci_boosa_cikar() TO drivekeep_app_user;


--
-- TOC entry 6232 (class 0 OID 0)
-- Dependencies: 743
-- Name: FUNCTION overlaps_2d(public.box2df, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6233 (class 0 OID 0)
-- Dependencies: 449
-- Name: FUNCTION overlaps_2d(public.box2df, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.box2df, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6234 (class 0 OID 0)
-- Dependencies: 641
-- Name: FUNCTION overlaps_2d(public.geometry, public.box2df); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_2d(public.geometry, public.box2df) TO drivekeep_app_user;


--
-- TOC entry 6235 (class 0 OID 0)
-- Dependencies: 770
-- Name: FUNCTION overlaps_geog(public.geography, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.geography, public.gidx) TO drivekeep_app_user;


--
-- TOC entry 6236 (class 0 OID 0)
-- Dependencies: 310
-- Name: FUNCTION overlaps_geog(public.gidx, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6237 (class 0 OID 0)
-- Dependencies: 490
-- Name: FUNCTION overlaps_geog(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_geog(public.gidx, public.gidx) TO drivekeep_app_user;


--
-- TOC entry 6238 (class 0 OID 0)
-- Dependencies: 792
-- Name: FUNCTION overlaps_nd(public.geometry, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.geometry, public.gidx) TO drivekeep_app_user;


--
-- TOC entry 6239 (class 0 OID 0)
-- Dependencies: 597
-- Name: FUNCTION overlaps_nd(public.gidx, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6240 (class 0 OID 0)
-- Dependencies: 495
-- Name: FUNCTION overlaps_nd(public.gidx, public.gidx); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.overlaps_nd(public.gidx, public.gidx) TO drivekeep_app_user;


--
-- TOC entry 6241 (class 0 OID 0)
-- Dependencies: 305
-- Name: FUNCTION pgis_asflatgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6242 (class 0 OID 0)
-- Dependencies: 525
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO drivekeep_app_user;


--
-- TOC entry 6243 (class 0 OID 0)
-- Dependencies: 699
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO drivekeep_app_user;


--
-- TOC entry 6244 (class 0 OID 0)
-- Dependencies: 983
-- Name: FUNCTION pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO drivekeep_app_user;


--
-- TOC entry 6245 (class 0 OID 0)
-- Dependencies: 326
-- Name: FUNCTION pgis_asgeobuf_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6246 (class 0 OID 0)
-- Dependencies: 721
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO drivekeep_app_user;


--
-- TOC entry 6247 (class 0 OID 0)
-- Dependencies: 776
-- Name: FUNCTION pgis_asgeobuf_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO drivekeep_app_user;


--
-- TOC entry 6248 (class 0 OID 0)
-- Dependencies: 965
-- Name: FUNCTION pgis_asmvt_combinefn(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6249 (class 0 OID 0)
-- Dependencies: 299
-- Name: FUNCTION pgis_asmvt_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO drivekeep_app_user;


--
-- TOC entry 6250 (class 0 OID 0)
-- Dependencies: 664
-- Name: FUNCTION pgis_asmvt_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6251 (class 0 OID 0)
-- Dependencies: 932
-- Name: FUNCTION pgis_asmvt_serialfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_serialfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6252 (class 0 OID 0)
-- Dependencies: 284
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO drivekeep_app_user;


--
-- TOC entry 6253 (class 0 OID 0)
-- Dependencies: 832
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO drivekeep_app_user;


--
-- TOC entry 6254 (class 0 OID 0)
-- Dependencies: 513
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO drivekeep_app_user;


--
-- TOC entry 6255 (class 0 OID 0)
-- Dependencies: 997
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO drivekeep_app_user;


--
-- TOC entry 6256 (class 0 OID 0)
-- Dependencies: 551
-- Name: FUNCTION pgis_asmvt_transfn(internal, anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO drivekeep_app_user;


--
-- TOC entry 6257 (class 0 OID 0)
-- Dependencies: 987
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6258 (class 0 OID 0)
-- Dependencies: 318
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6259 (class 0 OID 0)
-- Dependencies: 890
-- Name: FUNCTION pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_accum_transfn(internal, public.geometry, double precision, integer) TO drivekeep_app_user;


--
-- TOC entry 6260 (class 0 OID 0)
-- Dependencies: 700
-- Name: FUNCTION pgis_geometry_clusterintersecting_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6261 (class 0 OID 0)
-- Dependencies: 462
-- Name: FUNCTION pgis_geometry_clusterwithin_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6262 (class 0 OID 0)
-- Dependencies: 341
-- Name: FUNCTION pgis_geometry_collect_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6263 (class 0 OID 0)
-- Dependencies: 821
-- Name: FUNCTION pgis_geometry_coverageunion_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_coverageunion_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6264 (class 0 OID 0)
-- Dependencies: 248
-- Name: FUNCTION pgis_geometry_makeline_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6265 (class 0 OID 0)
-- Dependencies: 544
-- Name: FUNCTION pgis_geometry_polygonize_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6266 (class 0 OID 0)
-- Dependencies: 336
-- Name: FUNCTION pgis_geometry_union_parallel_combinefn(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO drivekeep_app_user;


--
-- TOC entry 6267 (class 0 OID 0)
-- Dependencies: 655
-- Name: FUNCTION pgis_geometry_union_parallel_deserialfn(bytea, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO drivekeep_app_user;


--
-- TOC entry 6268 (class 0 OID 0)
-- Dependencies: 958
-- Name: FUNCTION pgis_geometry_union_parallel_finalfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6269 (class 0 OID 0)
-- Dependencies: 481
-- Name: FUNCTION pgis_geometry_union_parallel_serialfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6270 (class 0 OID 0)
-- Dependencies: 431
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6271 (class 0 OID 0)
-- Dependencies: 802
-- Name: FUNCTION pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6272 (class 0 OID 0)
-- Dependencies: 904
-- Name: FUNCTION populate_geometry_columns(use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO drivekeep_app_user;


--
-- TOC entry 6273 (class 0 OID 0)
-- Dependencies: 473
-- Name: FUNCTION populate_geometry_columns(tbl_oid oid, use_typmod boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO drivekeep_app_user;


--
-- TOC entry 6274 (class 0 OID 0)
-- Dependencies: 837
-- Name: FUNCTION postgis_addbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_addbbox(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6275 (class 0 OID 0)
-- Dependencies: 634
-- Name: FUNCTION postgis_cache_bbox(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_cache_bbox() TO drivekeep_app_user;


--
-- TOC entry 6276 (class 0 OID 0)
-- Dependencies: 548
-- Name: FUNCTION postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO drivekeep_app_user;


--
-- TOC entry 6277 (class 0 OID 0)
-- Dependencies: 920
-- Name: FUNCTION postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO drivekeep_app_user;


--
-- TOC entry 6278 (class 0 OID 0)
-- Dependencies: 713
-- Name: FUNCTION postgis_constraint_type(geomschema text, geomtable text, geomcolumn text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO drivekeep_app_user;


--
-- TOC entry 6279 (class 0 OID 0)
-- Dependencies: 805
-- Name: FUNCTION postgis_dropbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_dropbbox(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6280 (class 0 OID 0)
-- Dependencies: 375
-- Name: FUNCTION postgis_extensions_upgrade(target_version text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_extensions_upgrade(target_version text) TO drivekeep_app_user;


--
-- TOC entry 6281 (class 0 OID 0)
-- Dependencies: 282
-- Name: FUNCTION postgis_full_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_full_version() TO drivekeep_app_user;


--
-- TOC entry 6282 (class 0 OID 0)
-- Dependencies: 439
-- Name: FUNCTION postgis_geos_compiled_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_geos_compiled_version() TO drivekeep_app_user;


--
-- TOC entry 6283 (class 0 OID 0)
-- Dependencies: 726
-- Name: FUNCTION postgis_geos_noop(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_geos_noop(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6284 (class 0 OID 0)
-- Dependencies: 528
-- Name: FUNCTION postgis_geos_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_geos_version() TO drivekeep_app_user;


--
-- TOC entry 6285 (class 0 OID 0)
-- Dependencies: 491
-- Name: FUNCTION postgis_getbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_getbbox(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6286 (class 0 OID 0)
-- Dependencies: 829
-- Name: FUNCTION postgis_hasbbox(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_hasbbox(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6287 (class 0 OID 0)
-- Dependencies: 950
-- Name: FUNCTION postgis_index_supportfn(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_index_supportfn(internal) TO drivekeep_app_user;


--
-- TOC entry 6288 (class 0 OID 0)
-- Dependencies: 853
-- Name: FUNCTION postgis_lib_build_date(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_lib_build_date() TO drivekeep_app_user;


--
-- TOC entry 6289 (class 0 OID 0)
-- Dependencies: 704
-- Name: FUNCTION postgis_lib_revision(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_lib_revision() TO drivekeep_app_user;


--
-- TOC entry 6290 (class 0 OID 0)
-- Dependencies: 355
-- Name: FUNCTION postgis_lib_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_lib_version() TO drivekeep_app_user;


--
-- TOC entry 6291 (class 0 OID 0)
-- Dependencies: 357
-- Name: FUNCTION postgis_libjson_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_libjson_version() TO drivekeep_app_user;


--
-- TOC entry 6292 (class 0 OID 0)
-- Dependencies: 894
-- Name: FUNCTION postgis_liblwgeom_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_liblwgeom_version() TO drivekeep_app_user;


--
-- TOC entry 6293 (class 0 OID 0)
-- Dependencies: 981
-- Name: FUNCTION postgis_libprotobuf_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_libprotobuf_version() TO drivekeep_app_user;


--
-- TOC entry 6294 (class 0 OID 0)
-- Dependencies: 838
-- Name: FUNCTION postgis_libxml_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_libxml_version() TO drivekeep_app_user;


--
-- TOC entry 6295 (class 0 OID 0)
-- Dependencies: 521
-- Name: FUNCTION postgis_noop(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_noop(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6296 (class 0 OID 0)
-- Dependencies: 414
-- Name: FUNCTION postgis_proj_compiled_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_proj_compiled_version() TO drivekeep_app_user;


--
-- TOC entry 6297 (class 0 OID 0)
-- Dependencies: 784
-- Name: FUNCTION postgis_proj_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_proj_version() TO drivekeep_app_user;


--
-- TOC entry 6298 (class 0 OID 0)
-- Dependencies: 766
-- Name: FUNCTION postgis_scripts_build_date(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_scripts_build_date() TO drivekeep_app_user;


--
-- TOC entry 6299 (class 0 OID 0)
-- Dependencies: 472
-- Name: FUNCTION postgis_scripts_installed(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_scripts_installed() TO drivekeep_app_user;


--
-- TOC entry 6300 (class 0 OID 0)
-- Dependencies: 939
-- Name: FUNCTION postgis_scripts_released(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_scripts_released() TO drivekeep_app_user;


--
-- TOC entry 6301 (class 0 OID 0)
-- Dependencies: 706
-- Name: FUNCTION postgis_srs(auth_name text, auth_srid text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs(auth_name text, auth_srid text) TO drivekeep_app_user;


--
-- TOC entry 6302 (class 0 OID 0)
-- Dependencies: 1003
-- Name: FUNCTION postgis_srs_all(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs_all() TO drivekeep_app_user;


--
-- TOC entry 6303 (class 0 OID 0)
-- Dependencies: 391
-- Name: FUNCTION postgis_srs_codes(auth_name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs_codes(auth_name text) TO drivekeep_app_user;


--
-- TOC entry 6304 (class 0 OID 0)
-- Dependencies: 317
-- Name: FUNCTION postgis_srs_search(bounds public.geometry, authname text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_srs_search(bounds public.geometry, authname text) TO drivekeep_app_user;


--
-- TOC entry 6305 (class 0 OID 0)
-- Dependencies: 736
-- Name: FUNCTION postgis_svn_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_svn_version() TO drivekeep_app_user;


--
-- TOC entry 6306 (class 0 OID 0)
-- Dependencies: 610
-- Name: FUNCTION postgis_transform_geometry(geom public.geometry, text, text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_transform_geometry(geom public.geometry, text, text, integer) TO drivekeep_app_user;


--
-- TOC entry 6307 (class 0 OID 0)
-- Dependencies: 764
-- Name: FUNCTION postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_transform_pipeline_geometry(geom public.geometry, pipeline text, forward boolean, to_srid integer) TO drivekeep_app_user;


--
-- TOC entry 6308 (class 0 OID 0)
-- Dependencies: 940
-- Name: FUNCTION postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO drivekeep_app_user;


--
-- TOC entry 6309 (class 0 OID 0)
-- Dependencies: 800
-- Name: FUNCTION postgis_typmod_dims(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_typmod_dims(integer) TO drivekeep_app_user;


--
-- TOC entry 6310 (class 0 OID 0)
-- Dependencies: 787
-- Name: FUNCTION postgis_typmod_srid(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_typmod_srid(integer) TO drivekeep_app_user;


--
-- TOC entry 6311 (class 0 OID 0)
-- Dependencies: 260
-- Name: FUNCTION postgis_typmod_type(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_typmod_type(integer) TO drivekeep_app_user;


--
-- TOC entry 6312 (class 0 OID 0)
-- Dependencies: 963
-- Name: FUNCTION postgis_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_version() TO drivekeep_app_user;


--
-- TOC entry 6313 (class 0 OID 0)
-- Dependencies: 961
-- Name: FUNCTION postgis_wagyu_version(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgis_wagyu_version() TO drivekeep_app_user;


--
-- TOC entry 6314 (class 0 OID 0)
-- Dependencies: 876
-- Name: FUNCTION st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dclosestpoint(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6315 (class 0 OID 0)
-- Dependencies: 485
-- Name: FUNCTION st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3ddfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6316 (class 0 OID 0)
-- Dependencies: 831
-- Name: FUNCTION st_3ddistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3ddistance(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6317 (class 0 OID 0)
-- Dependencies: 607
-- Name: FUNCTION st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3ddwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6318 (class 0 OID 0)
-- Dependencies: 532
-- Name: FUNCTION st_3dintersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dintersects(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6319 (class 0 OID 0)
-- Dependencies: 563
-- Name: FUNCTION st_3dlength(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dlength(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6320 (class 0 OID 0)
-- Dependencies: 851
-- Name: FUNCTION st_3dlineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dlineinterpolatepoint(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6321 (class 0 OID 0)
-- Dependencies: 589
-- Name: FUNCTION st_3dlongestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dlongestline(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6322 (class 0 OID 0)
-- Dependencies: 376
-- Name: FUNCTION st_3dmakebox(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dmakebox(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6323 (class 0 OID 0)
-- Dependencies: 771
-- Name: FUNCTION st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dmaxdistance(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6324 (class 0 OID 0)
-- Dependencies: 586
-- Name: FUNCTION st_3dperimeter(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dperimeter(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6325 (class 0 OID 0)
-- Dependencies: 976
-- Name: FUNCTION st_3dshortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dshortestline(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6326 (class 0 OID 0)
-- Dependencies: 493
-- Name: FUNCTION st_addmeasure(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_addmeasure(public.geometry, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6327 (class 0 OID 0)
-- Dependencies: 444
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6328 (class 0 OID 0)
-- Dependencies: 674
-- Name: FUNCTION st_addpoint(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_addpoint(geom1 public.geometry, geom2 public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6329 (class 0 OID 0)
-- Dependencies: 508
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6330 (class 0 OID 0)
-- Dependencies: 389
-- Name: FUNCTION st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_affine(public.geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6331 (class 0 OID 0)
-- Dependencies: 865
-- Name: FUNCTION st_angle(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_angle(line1 public.geometry, line2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6332 (class 0 OID 0)
-- Dependencies: 649
-- Name: FUNCTION st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_angle(pt1 public.geometry, pt2 public.geometry, pt3 public.geometry, pt4 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6333 (class 0 OID 0)
-- Dependencies: 427
-- Name: FUNCTION st_area(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area(text) TO drivekeep_app_user;


--
-- TOC entry 6334 (class 0 OID 0)
-- Dependencies: 781
-- Name: FUNCTION st_area(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6335 (class 0 OID 0)
-- Dependencies: 724
-- Name: FUNCTION st_area(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area(geog public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6336 (class 0 OID 0)
-- Dependencies: 734
-- Name: FUNCTION st_area2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_area2d(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6337 (class 0 OID 0)
-- Dependencies: 809
-- Name: FUNCTION st_asbinary(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6338 (class 0 OID 0)
-- Dependencies: 917
-- Name: FUNCTION st_asbinary(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6339 (class 0 OID 0)
-- Dependencies: 768
-- Name: FUNCTION st_asbinary(public.geography, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geography, text) TO drivekeep_app_user;


--
-- TOC entry 6340 (class 0 OID 0)
-- Dependencies: 656
-- Name: FUNCTION st_asbinary(public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asbinary(public.geometry, text) TO drivekeep_app_user;


--
-- TOC entry 6341 (class 0 OID 0)
-- Dependencies: 778
-- Name: FUNCTION st_asencodedpolyline(geom public.geometry, nprecision integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asencodedpolyline(geom public.geometry, nprecision integer) TO drivekeep_app_user;


--
-- TOC entry 6342 (class 0 OID 0)
-- Dependencies: 728
-- Name: FUNCTION st_asewkb(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6343 (class 0 OID 0)
-- Dependencies: 899
-- Name: FUNCTION st_asewkb(public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkb(public.geometry, text) TO drivekeep_app_user;


--
-- TOC entry 6344 (class 0 OID 0)
-- Dependencies: 543
-- Name: FUNCTION st_asewkt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(text) TO drivekeep_app_user;


--
-- TOC entry 6345 (class 0 OID 0)
-- Dependencies: 271
-- Name: FUNCTION st_asewkt(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6346 (class 0 OID 0)
-- Dependencies: 905
-- Name: FUNCTION st_asewkt(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6347 (class 0 OID 0)
-- Dependencies: 440
-- Name: FUNCTION st_asewkt(public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geography, integer) TO drivekeep_app_user;


--
-- TOC entry 6348 (class 0 OID 0)
-- Dependencies: 456
-- Name: FUNCTION st_asewkt(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asewkt(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6349 (class 0 OID 0)
-- Dependencies: 994
-- Name: FUNCTION st_asgeojson(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(text) TO drivekeep_app_user;


--
-- TOC entry 6350 (class 0 OID 0)
-- Dependencies: 914
-- Name: FUNCTION st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(geog public.geography, maxdecimaldigits integer, options integer) TO drivekeep_app_user;


--
-- TOC entry 6351 (class 0 OID 0)
-- Dependencies: 852
-- Name: FUNCTION st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(geom public.geometry, maxdecimaldigits integer, options integer) TO drivekeep_app_user;


--
-- TOC entry 6352 (class 0 OID 0)
-- Dependencies: 806
-- Name: FUNCTION st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean, id_column text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean, id_column text) TO drivekeep_app_user;


--
-- TOC entry 6353 (class 0 OID 0)
-- Dependencies: 505
-- Name: FUNCTION st_asgml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(text) TO drivekeep_app_user;


--
-- TOC entry 6354 (class 0 OID 0)
-- Dependencies: 394
-- Name: FUNCTION st_asgml(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(geom public.geometry, maxdecimaldigits integer, options integer) TO drivekeep_app_user;


--
-- TOC entry 6355 (class 0 OID 0)
-- Dependencies: 632
-- Name: FUNCTION st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO drivekeep_app_user;


--
-- TOC entry 6356 (class 0 OID 0)
-- Dependencies: 626
-- Name: FUNCTION st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geog public.geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO drivekeep_app_user;


--
-- TOC entry 6357 (class 0 OID 0)
-- Dependencies: 995
-- Name: FUNCTION st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgml(version integer, geom public.geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO drivekeep_app_user;


--
-- TOC entry 6358 (class 0 OID 0)
-- Dependencies: 418
-- Name: FUNCTION st_ashexewkb(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6359 (class 0 OID 0)
-- Dependencies: 717
-- Name: FUNCTION st_ashexewkb(public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ashexewkb(public.geometry, text) TO drivekeep_app_user;


--
-- TOC entry 6360 (class 0 OID 0)
-- Dependencies: 558
-- Name: FUNCTION st_askml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_askml(text) TO drivekeep_app_user;


--
-- TOC entry 6361 (class 0 OID 0)
-- Dependencies: 772
-- Name: FUNCTION st_askml(geog public.geography, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_askml(geog public.geography, maxdecimaldigits integer, nprefix text) TO drivekeep_app_user;


--
-- TOC entry 6362 (class 0 OID 0)
-- Dependencies: 545
-- Name: FUNCTION st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_askml(geom public.geometry, maxdecimaldigits integer, nprefix text) TO drivekeep_app_user;


--
-- TOC entry 6363 (class 0 OID 0)
-- Dependencies: 450
-- Name: FUNCTION st_aslatlontext(geom public.geometry, tmpl text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_aslatlontext(geom public.geometry, tmpl text) TO drivekeep_app_user;


--
-- TOC entry 6364 (class 0 OID 0)
-- Dependencies: 461
-- Name: FUNCTION st_asmarc21(geom public.geometry, format text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmarc21(geom public.geometry, format text) TO drivekeep_app_user;


--
-- TOC entry 6365 (class 0 OID 0)
-- Dependencies: 524
-- Name: FUNCTION st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvtgeom(geom public.geometry, bounds public.box2d, extent integer, buffer integer, clip_geom boolean) TO drivekeep_app_user;


--
-- TOC entry 6366 (class 0 OID 0)
-- Dependencies: 604
-- Name: FUNCTION st_assvg(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_assvg(text) TO drivekeep_app_user;


--
-- TOC entry 6367 (class 0 OID 0)
-- Dependencies: 576
-- Name: FUNCTION st_assvg(geog public.geography, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_assvg(geog public.geography, rel integer, maxdecimaldigits integer) TO drivekeep_app_user;


--
-- TOC entry 6368 (class 0 OID 0)
-- Dependencies: 870
-- Name: FUNCTION st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_assvg(geom public.geometry, rel integer, maxdecimaldigits integer) TO drivekeep_app_user;


--
-- TOC entry 6369 (class 0 OID 0)
-- Dependencies: 672
-- Name: FUNCTION st_astext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(text) TO drivekeep_app_user;


--
-- TOC entry 6370 (class 0 OID 0)
-- Dependencies: 667
-- Name: FUNCTION st_astext(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6371 (class 0 OID 0)
-- Dependencies: 596
-- Name: FUNCTION st_astext(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6372 (class 0 OID 0)
-- Dependencies: 601
-- Name: FUNCTION st_astext(public.geography, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geography, integer) TO drivekeep_app_user;


--
-- TOC entry 6373 (class 0 OID 0)
-- Dependencies: 464
-- Name: FUNCTION st_astext(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astext(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6374 (class 0 OID 0)
-- Dependencies: 471
-- Name: FUNCTION st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO drivekeep_app_user;


--
-- TOC entry 6375 (class 0 OID 0)
-- Dependencies: 426
-- Name: FUNCTION st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_astwkb(geom public.geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO drivekeep_app_user;


--
-- TOC entry 6376 (class 0 OID 0)
-- Dependencies: 681
-- Name: FUNCTION st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asx3d(geom public.geometry, maxdecimaldigits integer, options integer) TO drivekeep_app_user;


--
-- TOC entry 6377 (class 0 OID 0)
-- Dependencies: 330
-- Name: FUNCTION st_azimuth(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_azimuth(geog1 public.geography, geog2 public.geography) TO drivekeep_app_user;


--
-- TOC entry 6378 (class 0 OID 0)
-- Dependencies: 977
-- Name: FUNCTION st_azimuth(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_azimuth(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6379 (class 0 OID 0)
-- Dependencies: 648
-- Name: FUNCTION st_bdmpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6380 (class 0 OID 0)
-- Dependencies: 280
-- Name: FUNCTION st_bdpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_bdpolyfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6381 (class 0 OID 0)
-- Dependencies: 694
-- Name: FUNCTION st_boundary(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_boundary(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6382 (class 0 OID 0)
-- Dependencies: 278
-- Name: FUNCTION st_boundingdiagonal(geom public.geometry, fits boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_boundingdiagonal(geom public.geometry, fits boolean) TO drivekeep_app_user;


--
-- TOC entry 6383 (class 0 OID 0)
-- Dependencies: 413
-- Name: FUNCTION st_box2dfromgeohash(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_box2dfromgeohash(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6384 (class 0 OID 0)
-- Dependencies: 785
-- Name: FUNCTION st_buffer(text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision) TO drivekeep_app_user;


--
-- TOC entry 6385 (class 0 OID 0)
-- Dependencies: 240
-- Name: FUNCTION st_buffer(public.geography, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision) TO drivekeep_app_user;


--
-- TOC entry 6386 (class 0 OID 0)
-- Dependencies: 367
-- Name: FUNCTION st_buffer(text, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, integer) TO drivekeep_app_user;


--
-- TOC entry 6387 (class 0 OID 0)
-- Dependencies: 936
-- Name: FUNCTION st_buffer(text, double precision, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(text, double precision, text) TO drivekeep_app_user;


--
-- TOC entry 6388 (class 0 OID 0)
-- Dependencies: 612
-- Name: FUNCTION st_buffer(public.geography, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, integer) TO drivekeep_app_user;


--
-- TOC entry 6389 (class 0 OID 0)
-- Dependencies: 289
-- Name: FUNCTION st_buffer(public.geography, double precision, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(public.geography, double precision, text) TO drivekeep_app_user;


--
-- TOC entry 6390 (class 0 OID 0)
-- Dependencies: 910
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, quadsegs integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, quadsegs integer) TO drivekeep_app_user;


--
-- TOC entry 6391 (class 0 OID 0)
-- Dependencies: 788
-- Name: FUNCTION st_buffer(geom public.geometry, radius double precision, options text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buffer(geom public.geometry, radius double precision, options text) TO drivekeep_app_user;


--
-- TOC entry 6392 (class 0 OID 0)
-- Dependencies: 487
-- Name: FUNCTION st_buildarea(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_buildarea(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6393 (class 0 OID 0)
-- Dependencies: 526
-- Name: FUNCTION st_centroid(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_centroid(text) TO drivekeep_app_user;


--
-- TOC entry 6394 (class 0 OID 0)
-- Dependencies: 720
-- Name: FUNCTION st_centroid(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_centroid(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6395 (class 0 OID 0)
-- Dependencies: 269
-- Name: FUNCTION st_centroid(public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_centroid(public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6396 (class 0 OID 0)
-- Dependencies: 593
-- Name: FUNCTION st_chaikinsmoothing(public.geometry, integer, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_chaikinsmoothing(public.geometry, integer, boolean) TO drivekeep_app_user;


--
-- TOC entry 6397 (class 0 OID 0)
-- Dependencies: 600
-- Name: FUNCTION st_cleangeometry(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_cleangeometry(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6398 (class 0 OID 0)
-- Dependencies: 321
-- Name: FUNCTION st_clipbybox2d(geom public.geometry, box public.box2d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clipbybox2d(geom public.geometry, box public.box2d) TO drivekeep_app_user;


--
-- TOC entry 6399 (class 0 OID 0)
-- Dependencies: 588
-- Name: FUNCTION st_closestpoint(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpoint(text, text) TO drivekeep_app_user;


--
-- TOC entry 6400 (class 0 OID 0)
-- Dependencies: 942
-- Name: FUNCTION st_closestpoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpoint(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6401 (class 0 OID 0)
-- Dependencies: 265
-- Name: FUNCTION st_closestpoint(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpoint(public.geography, public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6402 (class 0 OID 0)
-- Dependencies: 779
-- Name: FUNCTION st_closestpointofapproach(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_closestpointofapproach(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6403 (class 0 OID 0)
-- Dependencies: 892
-- Name: FUNCTION st_clusterdbscan(public.geometry, eps double precision, minpoints integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterdbscan(public.geometry, eps double precision, minpoints integer) TO drivekeep_app_user;


--
-- TOC entry 6404 (class 0 OID 0)
-- Dependencies: 488
-- Name: FUNCTION st_clusterintersecting(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6405 (class 0 OID 0)
-- Dependencies: 836
-- Name: FUNCTION st_clusterintersectingwin(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterintersectingwin(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6406 (class 0 OID 0)
-- Dependencies: 791
-- Name: FUNCTION st_clusterkmeans(geom public.geometry, k integer, max_radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterkmeans(geom public.geometry, k integer, max_radius double precision) TO drivekeep_app_user;


--
-- TOC entry 6407 (class 0 OID 0)
-- Dependencies: 698
-- Name: FUNCTION st_clusterwithin(public.geometry[], double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry[], double precision) TO drivekeep_app_user;


--
-- TOC entry 6408 (class 0 OID 0)
-- Dependencies: 378
-- Name: FUNCTION st_clusterwithinwin(public.geometry, distance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterwithinwin(public.geometry, distance double precision) TO drivekeep_app_user;


--
-- TOC entry 6409 (class 0 OID 0)
-- Dependencies: 696
-- Name: FUNCTION st_collect(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6410 (class 0 OID 0)
-- Dependencies: 924
-- Name: FUNCTION st_collect(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collect(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6411 (class 0 OID 0)
-- Dependencies: 702
-- Name: FUNCTION st_collectionextract(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6412 (class 0 OID 0)
-- Dependencies: 642
-- Name: FUNCTION st_collectionextract(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collectionextract(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6413 (class 0 OID 0)
-- Dependencies: 956
-- Name: FUNCTION st_collectionhomogenize(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collectionhomogenize(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6414 (class 0 OID 0)
-- Dependencies: 382
-- Name: FUNCTION st_combinebbox(public.box2d, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box2d, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6415 (class 0 OID 0)
-- Dependencies: 469
-- Name: FUNCTION st_combinebbox(public.box3d, public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6416 (class 0 OID 0)
-- Dependencies: 786
-- Name: FUNCTION st_combinebbox(public.box3d, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_combinebbox(public.box3d, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6417 (class 0 OID 0)
-- Dependencies: 757
-- Name: FUNCTION st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_concavehull(param_geom public.geometry, param_pctconvex double precision, param_allow_holes boolean) TO drivekeep_app_user;


--
-- TOC entry 6418 (class 0 OID 0)
-- Dependencies: 679
-- Name: FUNCTION st_contains(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_contains(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6419 (class 0 OID 0)
-- Dependencies: 333
-- Name: FUNCTION st_containsproperly(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_containsproperly(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6420 (class 0 OID 0)
-- Dependencies: 738
-- Name: FUNCTION st_convexhull(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_convexhull(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6421 (class 0 OID 0)
-- Dependencies: 437
-- Name: FUNCTION st_coorddim(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coorddim(geometry public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6422 (class 0 OID 0)
-- Dependencies: 374
-- Name: FUNCTION st_coverageclean(geom public.geometry, gapmaximumwidth double precision, snappingdistance double precision, overlapmergestrategy text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageclean(geom public.geometry, gapmaximumwidth double precision, snappingdistance double precision, overlapmergestrategy text) TO drivekeep_app_user;


--
-- TOC entry 6423 (class 0 OID 0)
-- Dependencies: 731
-- Name: FUNCTION st_coverageinvalidedges(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageinvalidedges(geom public.geometry, tolerance double precision) TO drivekeep_app_user;


--
-- TOC entry 6424 (class 0 OID 0)
-- Dependencies: 701
-- Name: FUNCTION st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveragesimplify(geom public.geometry, tolerance double precision, simplifyboundary boolean) TO drivekeep_app_user;


--
-- TOC entry 6425 (class 0 OID 0)
-- Dependencies: 585
-- Name: FUNCTION st_coverageunion(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6426 (class 0 OID 0)
-- Dependencies: 896
-- Name: FUNCTION st_coveredby(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveredby(text, text) TO drivekeep_app_user;


--
-- TOC entry 6427 (class 0 OID 0)
-- Dependencies: 889
-- Name: FUNCTION st_coveredby(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveredby(geog1 public.geography, geog2 public.geography) TO drivekeep_app_user;


--
-- TOC entry 6428 (class 0 OID 0)
-- Dependencies: 861
-- Name: FUNCTION st_coveredby(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coveredby(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6429 (class 0 OID 0)
-- Dependencies: 868
-- Name: FUNCTION st_covers(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_covers(text, text) TO drivekeep_app_user;


--
-- TOC entry 6430 (class 0 OID 0)
-- Dependencies: 251
-- Name: FUNCTION st_covers(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_covers(geog1 public.geography, geog2 public.geography) TO drivekeep_app_user;


--
-- TOC entry 6431 (class 0 OID 0)
-- Dependencies: 999
-- Name: FUNCTION st_covers(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_covers(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6432 (class 0 OID 0)
-- Dependencies: 810
-- Name: FUNCTION st_cpawithin(public.geometry, public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_cpawithin(public.geometry, public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6433 (class 0 OID 0)
-- Dependencies: 752
-- Name: FUNCTION st_crosses(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_crosses(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6434 (class 0 OID 0)
-- Dependencies: 769
-- Name: FUNCTION st_curven(geometry public.geometry, i integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_curven(geometry public.geometry, i integer) TO drivekeep_app_user;


--
-- TOC entry 6435 (class 0 OID 0)
-- Dependencies: 569
-- Name: FUNCTION st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_curvetoline(geom public.geometry, tol double precision, toltype integer, flags integer) TO drivekeep_app_user;


--
-- TOC entry 6436 (class 0 OID 0)
-- Dependencies: 560
-- Name: FUNCTION st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_delaunaytriangles(g1 public.geometry, tolerance double precision, flags integer) TO drivekeep_app_user;


--
-- TOC entry 6437 (class 0 OID 0)
-- Dependencies: 296
-- Name: FUNCTION st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dfullywithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6438 (class 0 OID 0)
-- Dependencies: 363
-- Name: FUNCTION st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_difference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6439 (class 0 OID 0)
-- Dependencies: 639
-- Name: FUNCTION st_dimension(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dimension(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6440 (class 0 OID 0)
-- Dependencies: 733
-- Name: FUNCTION st_disjoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_disjoint(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6441 (class 0 OID 0)
-- Dependencies: 859
-- Name: FUNCTION st_distance(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distance(text, text) TO drivekeep_app_user;


--
-- TOC entry 6442 (class 0 OID 0)
-- Dependencies: 825
-- Name: FUNCTION st_distance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distance(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6443 (class 0 OID 0)
-- Dependencies: 864
-- Name: FUNCTION st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distance(geog1 public.geography, geog2 public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6444 (class 0 OID 0)
-- Dependencies: 722
-- Name: FUNCTION st_distancecpa(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancecpa(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6445 (class 0 OID 0)
-- Dependencies: 583
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6446 (class 0 OID 0)
-- Dependencies: 708
-- Name: FUNCTION st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancesphere(geom1 public.geometry, geom2 public.geometry, radius double precision) TO drivekeep_app_user;


--
-- TOC entry 6447 (class 0 OID 0)
-- Dependencies: 605
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6448 (class 0 OID 0)
-- Dependencies: 556
-- Name: FUNCTION st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_distancespheroid(geom1 public.geometry, geom2 public.geometry, public.spheroid) TO drivekeep_app_user;


--
-- TOC entry 6449 (class 0 OID 0)
-- Dependencies: 970
-- Name: FUNCTION st_dump(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dump(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6450 (class 0 OID 0)
-- Dependencies: 396
-- Name: FUNCTION st_dumppoints(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dumppoints(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6451 (class 0 OID 0)
-- Dependencies: 516
-- Name: FUNCTION st_dumprings(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dumprings(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6452 (class 0 OID 0)
-- Dependencies: 744
-- Name: FUNCTION st_dumpsegments(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dumpsegments(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6453 (class 0 OID 0)
-- Dependencies: 998
-- Name: FUNCTION st_dwithin(text, text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dwithin(text, text, double precision) TO drivekeep_app_user;


--
-- TOC entry 6454 (class 0 OID 0)
-- Dependencies: 599
-- Name: FUNCTION st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dwithin(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6455 (class 0 OID 0)
-- Dependencies: 912
-- Name: FUNCTION st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_dwithin(geog1 public.geography, geog2 public.geography, tolerance double precision, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6456 (class 0 OID 0)
-- Dependencies: 578
-- Name: FUNCTION st_endpoint(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_endpoint(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6457 (class 0 OID 0)
-- Dependencies: 971
-- Name: FUNCTION st_envelope(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_envelope(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6458 (class 0 OID 0)
-- Dependencies: 993
-- Name: FUNCTION st_equals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_equals(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6459 (class 0 OID 0)
-- Dependencies: 343
-- Name: FUNCTION st_estimatedextent(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text) TO drivekeep_app_user;


--
-- TOC entry 6460 (class 0 OID 0)
-- Dependencies: 691
-- Name: FUNCTION st_estimatedextent(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text) TO drivekeep_app_user;


--
-- TOC entry 6461 (class 0 OID 0)
-- Dependencies: 652
-- Name: FUNCTION st_estimatedextent(text, text, text, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO drivekeep_app_user;


--
-- TOC entry 6462 (class 0 OID 0)
-- Dependencies: 259
-- Name: FUNCTION st_expand(public.box2d, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(public.box2d, double precision) TO drivekeep_app_user;


--
-- TOC entry 6463 (class 0 OID 0)
-- Dependencies: 497
-- Name: FUNCTION st_expand(public.box3d, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(public.box3d, double precision) TO drivekeep_app_user;


--
-- TOC entry 6464 (class 0 OID 0)
-- Dependencies: 249
-- Name: FUNCTION st_expand(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6465 (class 0 OID 0)
-- Dependencies: 482
-- Name: FUNCTION st_expand(box public.box2d, dx double precision, dy double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(box public.box2d, dx double precision, dy double precision) TO drivekeep_app_user;


--
-- TOC entry 6466 (class 0 OID 0)
-- Dependencies: 680
-- Name: FUNCTION st_expand(box public.box3d, dx double precision, dy double precision, dz double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(box public.box3d, dx double precision, dy double precision, dz double precision) TO drivekeep_app_user;


--
-- TOC entry 6467 (class 0 OID 0)
-- Dependencies: 875
-- Name: FUNCTION st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_expand(geom public.geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO drivekeep_app_user;


--
-- TOC entry 6468 (class 0 OID 0)
-- Dependencies: 671
-- Name: FUNCTION st_exteriorring(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_exteriorring(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6469 (class 0 OID 0)
-- Dependencies: 324
-- Name: FUNCTION st_filterbym(public.geometry, double precision, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_filterbym(public.geometry, double precision, double precision, boolean) TO drivekeep_app_user;


--
-- TOC entry 6470 (class 0 OID 0)
-- Dependencies: 818
-- Name: FUNCTION st_findextent(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_findextent(text, text) TO drivekeep_app_user;


--
-- TOC entry 6471 (class 0 OID 0)
-- Dependencies: 502
-- Name: FUNCTION st_findextent(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_findextent(text, text, text) TO drivekeep_app_user;


--
-- TOC entry 6472 (class 0 OID 0)
-- Dependencies: 879
-- Name: FUNCTION st_flipcoordinates(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_flipcoordinates(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6473 (class 0 OID 0)
-- Dependencies: 756
-- Name: FUNCTION st_force2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force2d(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6474 (class 0 OID 0)
-- Dependencies: 609
-- Name: FUNCTION st_force3d(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force3d(geom public.geometry, zvalue double precision) TO drivekeep_app_user;


--
-- TOC entry 6475 (class 0 OID 0)
-- Dependencies: 990
-- Name: FUNCTION st_force3dm(geom public.geometry, mvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force3dm(geom public.geometry, mvalue double precision) TO drivekeep_app_user;


--
-- TOC entry 6476 (class 0 OID 0)
-- Dependencies: 390
-- Name: FUNCTION st_force3dz(geom public.geometry, zvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force3dz(geom public.geometry, zvalue double precision) TO drivekeep_app_user;


--
-- TOC entry 6477 (class 0 OID 0)
-- Dependencies: 519
-- Name: FUNCTION st_force4d(geom public.geometry, zvalue double precision, mvalue double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_force4d(geom public.geometry, zvalue double precision, mvalue double precision) TO drivekeep_app_user;


--
-- TOC entry 6478 (class 0 OID 0)
-- Dependencies: 819
-- Name: FUNCTION st_forcecollection(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcecollection(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6479 (class 0 OID 0)
-- Dependencies: 761
-- Name: FUNCTION st_forcecurve(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcecurve(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6480 (class 0 OID 0)
-- Dependencies: 946
-- Name: FUNCTION st_forcepolygonccw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcepolygonccw(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6481 (class 0 OID 0)
-- Dependencies: 959
-- Name: FUNCTION st_forcepolygoncw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcepolygoncw(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6482 (class 0 OID 0)
-- Dependencies: 323
-- Name: FUNCTION st_forcerhr(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcerhr(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6483 (class 0 OID 0)
-- Dependencies: 922
-- Name: FUNCTION st_forcesfs(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6484 (class 0 OID 0)
-- Dependencies: 277
-- Name: FUNCTION st_forcesfs(public.geometry, version text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_forcesfs(public.geometry, version text) TO drivekeep_app_user;


--
-- TOC entry 6485 (class 0 OID 0)
-- Dependencies: 906
-- Name: FUNCTION st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_frechetdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6486 (class 0 OID 0)
-- Dependencies: 411
-- Name: FUNCTION st_fromflatgeobuf(anyelement, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO drivekeep_app_user;


--
-- TOC entry 6487 (class 0 OID 0)
-- Dependencies: 294
-- Name: FUNCTION st_fromflatgeobuftotable(text, text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO drivekeep_app_user;


--
-- TOC entry 6488 (class 0 OID 0)
-- Dependencies: 826
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer) TO drivekeep_app_user;


--
-- TOC entry 6489 (class 0 OID 0)
-- Dependencies: 451
-- Name: FUNCTION st_generatepoints(area public.geometry, npoints integer, seed integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_generatepoints(area public.geometry, npoints integer, seed integer) TO drivekeep_app_user;


--
-- TOC entry 6490 (class 0 OID 0)
-- Dependencies: 989
-- Name: FUNCTION st_geogfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geogfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6491 (class 0 OID 0)
-- Dependencies: 824
-- Name: FUNCTION st_geogfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geogfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6492 (class 0 OID 0)
-- Dependencies: 540
-- Name: FUNCTION st_geographyfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geographyfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6493 (class 0 OID 0)
-- Dependencies: 522
-- Name: FUNCTION st_geohash(geog public.geography, maxchars integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geohash(geog public.geography, maxchars integer) TO drivekeep_app_user;


--
-- TOC entry 6494 (class 0 OID 0)
-- Dependencies: 933
-- Name: FUNCTION st_geohash(geom public.geometry, maxchars integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geohash(geom public.geometry, maxchars integer) TO drivekeep_app_user;


--
-- TOC entry 6495 (class 0 OID 0)
-- Dependencies: 803
-- Name: FUNCTION st_geomcollfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6496 (class 0 OID 0)
-- Dependencies: 850
-- Name: FUNCTION st_geomcollfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6497 (class 0 OID 0)
-- Dependencies: 384
-- Name: FUNCTION st_geomcollfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6498 (class 0 OID 0)
-- Dependencies: 331
-- Name: FUNCTION st_geomcollfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6499 (class 0 OID 0)
-- Dependencies: 740
-- Name: FUNCTION st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometricmedian(g public.geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO drivekeep_app_user;


--
-- TOC entry 6500 (class 0 OID 0)
-- Dependencies: 974
-- Name: FUNCTION st_geometryfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6501 (class 0 OID 0)
-- Dependencies: 350
-- Name: FUNCTION st_geometryfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometryfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6502 (class 0 OID 0)
-- Dependencies: 873
-- Name: FUNCTION st_geometryn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometryn(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6503 (class 0 OID 0)
-- Dependencies: 854
-- Name: FUNCTION st_geometrytype(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geometrytype(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6504 (class 0 OID 0)
-- Dependencies: 245
-- Name: FUNCTION st_geomfromewkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromewkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6505 (class 0 OID 0)
-- Dependencies: 300
-- Name: FUNCTION st_geomfromewkt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromewkt(text) TO drivekeep_app_user;


--
-- TOC entry 6506 (class 0 OID 0)
-- Dependencies: 529
-- Name: FUNCTION st_geomfromgeohash(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeohash(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6507 (class 0 OID 0)
-- Dependencies: 709
-- Name: FUNCTION st_geomfromgeojson(json); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(json) TO drivekeep_app_user;


--
-- TOC entry 6508 (class 0 OID 0)
-- Dependencies: 572
-- Name: FUNCTION st_geomfromgeojson(jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(jsonb) TO drivekeep_app_user;


--
-- TOC entry 6509 (class 0 OID 0)
-- Dependencies: 337
-- Name: FUNCTION st_geomfromgeojson(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgeojson(text) TO drivekeep_app_user;


--
-- TOC entry 6510 (class 0 OID 0)
-- Dependencies: 834
-- Name: FUNCTION st_geomfromgml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text) TO drivekeep_app_user;


--
-- TOC entry 6511 (class 0 OID 0)
-- Dependencies: 925
-- Name: FUNCTION st_geomfromgml(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromgml(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6512 (class 0 OID 0)
-- Dependencies: 849
-- Name: FUNCTION st_geomfromkml(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromkml(text) TO drivekeep_app_user;


--
-- TOC entry 6513 (class 0 OID 0)
-- Dependencies: 812
-- Name: FUNCTION st_geomfrommarc21(marc21xml text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO drivekeep_app_user;


--
-- TOC entry 6514 (class 0 OID 0)
-- Dependencies: 319
-- Name: FUNCTION st_geomfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6515 (class 0 OID 0)
-- Dependencies: 598
-- Name: FUNCTION st_geomfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6516 (class 0 OID 0)
-- Dependencies: 735
-- Name: FUNCTION st_geomfromtwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromtwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6517 (class 0 OID 0)
-- Dependencies: 695
-- Name: FUNCTION st_geomfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6518 (class 0 OID 0)
-- Dependencies: 808
-- Name: FUNCTION st_geomfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_geomfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6519 (class 0 OID 0)
-- Dependencies: 603
-- Name: FUNCTION st_gmltosql(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_gmltosql(text) TO drivekeep_app_user;


--
-- TOC entry 6520 (class 0 OID 0)
-- Dependencies: 703
-- Name: FUNCTION st_gmltosql(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_gmltosql(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6521 (class 0 OID 0)
-- Dependencies: 479
-- Name: FUNCTION st_hasarc(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hasarc(geometry public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6522 (class 0 OID 0)
-- Dependencies: 822
-- Name: FUNCTION st_hasm(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hasm(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6523 (class 0 OID 0)
-- Dependencies: 663
-- Name: FUNCTION st_hasz(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hasz(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6524 (class 0 OID 0)
-- Dependencies: 351
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6525 (class 0 OID 0)
-- Dependencies: 780
-- Name: FUNCTION st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hausdorffdistance(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6526 (class 0 OID 0)
-- Dependencies: 515
-- Name: FUNCTION st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6527 (class 0 OID 0)
-- Dependencies: 564
-- Name: FUNCTION st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_hexagongrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO drivekeep_app_user;


--
-- TOC entry 6528 (class 0 OID 0)
-- Dependencies: 442
-- Name: FUNCTION st_interiorringn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_interiorringn(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6529 (class 0 OID 0)
-- Dependencies: 379
-- Name: FUNCTION st_interpolatepoint(line public.geometry, point public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_interpolatepoint(line public.geometry, point public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6530 (class 0 OID 0)
-- Dependencies: 935
-- Name: FUNCTION st_intersection(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersection(text, text) TO drivekeep_app_user;


--
-- TOC entry 6531 (class 0 OID 0)
-- Dependencies: 840
-- Name: FUNCTION st_intersection(public.geography, public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersection(public.geography, public.geography) TO drivekeep_app_user;


--
-- TOC entry 6532 (class 0 OID 0)
-- Dependencies: 582
-- Name: FUNCTION st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersection(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6533 (class 0 OID 0)
-- Dependencies: 467
-- Name: FUNCTION st_intersects(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersects(text, text) TO drivekeep_app_user;


--
-- TOC entry 6534 (class 0 OID 0)
-- Dependencies: 611
-- Name: FUNCTION st_intersects(geog1 public.geography, geog2 public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersects(geog1 public.geography, geog2 public.geography) TO drivekeep_app_user;


--
-- TOC entry 6535 (class 0 OID 0)
-- Dependencies: 381
-- Name: FUNCTION st_intersects(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_intersects(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6536 (class 0 OID 0)
-- Dependencies: 320
-- Name: FUNCTION st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_inversetransformpipeline(geom public.geometry, pipeline text, to_srid integer) TO drivekeep_app_user;


--
-- TOC entry 6537 (class 0 OID 0)
-- Dependencies: 366
-- Name: FUNCTION st_isclosed(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isclosed(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6538 (class 0 OID 0)
-- Dependencies: 633
-- Name: FUNCTION st_iscollection(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_iscollection(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6539 (class 0 OID 0)
-- Dependencies: 266
-- Name: FUNCTION st_isempty(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isempty(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6540 (class 0 OID 0)
-- Dependencies: 590
-- Name: FUNCTION st_ispolygonccw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ispolygonccw(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6541 (class 0 OID 0)
-- Dependencies: 979
-- Name: FUNCTION st_ispolygoncw(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ispolygoncw(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6542 (class 0 OID 0)
-- Dependencies: 291
-- Name: FUNCTION st_isring(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isring(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6543 (class 0 OID 0)
-- Dependencies: 460
-- Name: FUNCTION st_issimple(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_issimple(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6544 (class 0 OID 0)
-- Dependencies: 883
-- Name: FUNCTION st_isvalid(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6545 (class 0 OID 0)
-- Dependencies: 978
-- Name: FUNCTION st_isvalid(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalid(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6546 (class 0 OID 0)
-- Dependencies: 982
-- Name: FUNCTION st_isvaliddetail(geom public.geometry, flags integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvaliddetail(geom public.geometry, flags integer) TO drivekeep_app_user;


--
-- TOC entry 6547 (class 0 OID 0)
-- Dependencies: 306
-- Name: FUNCTION st_isvalidreason(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6548 (class 0 OID 0)
-- Dependencies: 358
-- Name: FUNCTION st_isvalidreason(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalidreason(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6549 (class 0 OID 0)
-- Dependencies: 420
-- Name: FUNCTION st_isvalidtrajectory(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_isvalidtrajectory(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6550 (class 0 OID 0)
-- Dependencies: 542
-- Name: FUNCTION st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_largestemptycircle(geom public.geometry, tolerance double precision, boundary public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO drivekeep_app_user;


--
-- TOC entry 6551 (class 0 OID 0)
-- Dependencies: 630
-- Name: FUNCTION st_length(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length(text) TO drivekeep_app_user;


--
-- TOC entry 6552 (class 0 OID 0)
-- Dependencies: 867
-- Name: FUNCTION st_length(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6553 (class 0 OID 0)
-- Dependencies: 325
-- Name: FUNCTION st_length(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length(geog public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6554 (class 0 OID 0)
-- Dependencies: 302
-- Name: FUNCTION st_length2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length2d(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6555 (class 0 OID 0)
-- Dependencies: 392
-- Name: FUNCTION st_length2dspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_length2dspheroid(public.geometry, public.spheroid) TO drivekeep_app_user;


--
-- TOC entry 6556 (class 0 OID 0)
-- Dependencies: 453
-- Name: FUNCTION st_lengthspheroid(public.geometry, public.spheroid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lengthspheroid(public.geometry, public.spheroid) TO drivekeep_app_user;


--
-- TOC entry 6557 (class 0 OID 0)
-- Dependencies: 417
-- Name: FUNCTION st_letters(letters text, font json); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_letters(letters text, font json) TO drivekeep_app_user;


--
-- TOC entry 6558 (class 0 OID 0)
-- Dependencies: 443
-- Name: FUNCTION st_linecrossingdirection(line1 public.geometry, line2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linecrossingdirection(line1 public.geometry, line2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6559 (class 0 OID 0)
-- Dependencies: 907
-- Name: FUNCTION st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineextend(geom public.geometry, distance_forward double precision, distance_backward double precision) TO drivekeep_app_user;


--
-- TOC entry 6560 (class 0 OID 0)
-- Dependencies: 510
-- Name: FUNCTION st_linefromencodedpolyline(txtin text, nprecision integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO drivekeep_app_user;


--
-- TOC entry 6561 (class 0 OID 0)
-- Dependencies: 250
-- Name: FUNCTION st_linefrommultipoint(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefrommultipoint(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6562 (class 0 OID 0)
-- Dependencies: 606
-- Name: FUNCTION st_linefromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6563 (class 0 OID 0)
-- Dependencies: 501
-- Name: FUNCTION st_linefromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6564 (class 0 OID 0)
-- Dependencies: 247
-- Name: FUNCTION st_linefromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6565 (class 0 OID 0)
-- Dependencies: 345
-- Name: FUNCTION st_linefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linefromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6566 (class 0 OID 0)
-- Dependencies: 370
-- Name: FUNCTION st_lineinterpolatepoint(text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(text, double precision) TO drivekeep_app_user;


--
-- TOC entry 6567 (class 0 OID 0)
-- Dependencies: 746
-- Name: FUNCTION st_lineinterpolatepoint(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6568 (class 0 OID 0)
-- Dependencies: 741
-- Name: FUNCTION st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoint(public.geography, double precision, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6569 (class 0 OID 0)
-- Dependencies: 615
-- Name: FUNCTION st_lineinterpolatepoints(text, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(text, double precision) TO drivekeep_app_user;


--
-- TOC entry 6570 (class 0 OID 0)
-- Dependencies: 714
-- Name: FUNCTION st_lineinterpolatepoints(public.geometry, double precision, repeat boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geometry, double precision, repeat boolean) TO drivekeep_app_user;


--
-- TOC entry 6571 (class 0 OID 0)
-- Dependencies: 629
-- Name: FUNCTION st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_lineinterpolatepoints(public.geography, double precision, use_spheroid boolean, repeat boolean) TO drivekeep_app_user;


--
-- TOC entry 6572 (class 0 OID 0)
-- Dependencies: 666
-- Name: FUNCTION st_linelocatepoint(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(text, text) TO drivekeep_app_user;


--
-- TOC entry 6573 (class 0 OID 0)
-- Dependencies: 794
-- Name: FUNCTION st_linelocatepoint(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6574 (class 0 OID 0)
-- Dependencies: 549
-- Name: FUNCTION st_linelocatepoint(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linelocatepoint(public.geography, public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6575 (class 0 OID 0)
-- Dependencies: 992
-- Name: FUNCTION st_linemerge(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6576 (class 0 OID 0)
-- Dependencies: 303
-- Name: FUNCTION st_linemerge(public.geometry, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linemerge(public.geometry, boolean) TO drivekeep_app_user;


--
-- TOC entry 6577 (class 0 OID 0)
-- Dependencies: 401
-- Name: FUNCTION st_linestringfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6578 (class 0 OID 0)
-- Dependencies: 759
-- Name: FUNCTION st_linestringfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6579 (class 0 OID 0)
-- Dependencies: 682
-- Name: FUNCTION st_linesubstring(text, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linesubstring(text, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6580 (class 0 OID 0)
-- Dependencies: 373
-- Name: FUNCTION st_linesubstring(public.geography, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geography, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6581 (class 0 OID 0)
-- Dependencies: 872
-- Name: FUNCTION st_linesubstring(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linesubstring(public.geometry, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6582 (class 0 OID 0)
-- Dependencies: 723
-- Name: FUNCTION st_linetocurve(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_linetocurve(geometry public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6583 (class 0 OID 0)
-- Dependencies: 718
-- Name: FUNCTION st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_locatealong(geometry public.geometry, measure double precision, leftrightoffset double precision) TO drivekeep_app_user;


--
-- TOC entry 6584 (class 0 OID 0)
-- Dependencies: 547
-- Name: FUNCTION st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_locatebetween(geometry public.geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO drivekeep_app_user;


--
-- TOC entry 6585 (class 0 OID 0)
-- Dependencies: 430
-- Name: FUNCTION st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_locatebetweenelevations(geometry public.geometry, fromelevation double precision, toelevation double precision) TO drivekeep_app_user;


--
-- TOC entry 6586 (class 0 OID 0)
-- Dependencies: 403
-- Name: FUNCTION st_longestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_longestline(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6587 (class 0 OID 0)
-- Dependencies: 419
-- Name: FUNCTION st_m(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_m(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6588 (class 0 OID 0)
-- Dependencies: 514
-- Name: FUNCTION st_makebox2d(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makebox2d(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6589 (class 0 OID 0)
-- Dependencies: 949
-- Name: FUNCTION st_makeenvelope(double precision, double precision, double precision, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO drivekeep_app_user;


--
-- TOC entry 6590 (class 0 OID 0)
-- Dependencies: 623
-- Name: FUNCTION st_makeline(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6591 (class 0 OID 0)
-- Dependencies: 661
-- Name: FUNCTION st_makeline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeline(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6592 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION st_makepoint(double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6593 (class 0 OID 0)
-- Dependencies: 541
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6594 (class 0 OID 0)
-- Dependencies: 895
-- Name: FUNCTION st_makepoint(double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6595 (class 0 OID 0)
-- Dependencies: 531
-- Name: FUNCTION st_makepointm(double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6596 (class 0 OID 0)
-- Dependencies: 944
-- Name: FUNCTION st_makepolygon(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6597 (class 0 OID 0)
-- Dependencies: 338
-- Name: FUNCTION st_makepolygon(public.geometry, public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makepolygon(public.geometry, public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6598 (class 0 OID 0)
-- Dependencies: 964
-- Name: FUNCTION st_makevalid(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makevalid(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6599 (class 0 OID 0)
-- Dependencies: 916
-- Name: FUNCTION st_makevalid(geom public.geometry, params text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makevalid(geom public.geometry, params text) TO drivekeep_app_user;


--
-- TOC entry 6600 (class 0 OID 0)
-- Dependencies: 645
-- Name: FUNCTION st_maxdistance(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_maxdistance(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6601 (class 0 OID 0)
-- Dependencies: 398
-- Name: FUNCTION st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_maximuminscribedcircle(public.geometry, OUT center public.geometry, OUT nearest public.geometry, OUT radius double precision) TO drivekeep_app_user;


--
-- TOC entry 6602 (class 0 OID 0)
-- Dependencies: 584
-- Name: FUNCTION st_memsize(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_memsize(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6603 (class 0 OID 0)
-- Dependencies: 562
-- Name: FUNCTION st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumboundingcircle(inputgeom public.geometry, segs_per_quarter integer) TO drivekeep_app_user;


--
-- TOC entry 6604 (class 0 OID 0)
-- Dependencies: 332
-- Name: FUNCTION st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumboundingradius(public.geometry, OUT center public.geometry, OUT radius double precision) TO drivekeep_app_user;


--
-- TOC entry 6605 (class 0 OID 0)
-- Dependencies: 509
-- Name: FUNCTION st_minimumclearance(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumclearance(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6606 (class 0 OID 0)
-- Dependencies: 1002
-- Name: FUNCTION st_minimumclearanceline(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_minimumclearanceline(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6607 (class 0 OID 0)
-- Dependencies: 654
-- Name: FUNCTION st_mlinefromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6608 (class 0 OID 0)
-- Dependencies: 393
-- Name: FUNCTION st_mlinefromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6609 (class 0 OID 0)
-- Dependencies: 285
-- Name: FUNCTION st_mlinefromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6610 (class 0 OID 0)
-- Dependencies: 874
-- Name: FUNCTION st_mlinefromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6611 (class 0 OID 0)
-- Dependencies: 886
-- Name: FUNCTION st_mpointfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6612 (class 0 OID 0)
-- Dependencies: 334
-- Name: FUNCTION st_mpointfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6613 (class 0 OID 0)
-- Dependencies: 347
-- Name: FUNCTION st_mpointfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6614 (class 0 OID 0)
-- Dependencies: 486
-- Name: FUNCTION st_mpointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6615 (class 0 OID 0)
-- Dependencies: 841
-- Name: FUNCTION st_mpolyfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6616 (class 0 OID 0)
-- Dependencies: 798
-- Name: FUNCTION st_mpolyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6617 (class 0 OID 0)
-- Dependencies: 281
-- Name: FUNCTION st_mpolyfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6618 (class 0 OID 0)
-- Dependencies: 657
-- Name: FUNCTION st_mpolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6619 (class 0 OID 0)
-- Dependencies: 581
-- Name: FUNCTION st_multi(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multi(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6620 (class 0 OID 0)
-- Dependencies: 452
-- Name: FUNCTION st_multilinefromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multilinefromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6621 (class 0 OID 0)
-- Dependencies: 463
-- Name: FUNCTION st_multilinestringfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6622 (class 0 OID 0)
-- Dependencies: 628
-- Name: FUNCTION st_multilinestringfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multilinestringfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6623 (class 0 OID 0)
-- Dependencies: 372
-- Name: FUNCTION st_multipointfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipointfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6624 (class 0 OID 0)
-- Dependencies: 498
-- Name: FUNCTION st_multipointfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6625 (class 0 OID 0)
-- Dependencies: 885
-- Name: FUNCTION st_multipointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6626 (class 0 OID 0)
-- Dependencies: 286
-- Name: FUNCTION st_multipolyfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6627 (class 0 OID 0)
-- Dependencies: 1004
-- Name: FUNCTION st_multipolyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6628 (class 0 OID 0)
-- Dependencies: 258
-- Name: FUNCTION st_multipolygonfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6629 (class 0 OID 0)
-- Dependencies: 863
-- Name: FUNCTION st_multipolygonfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_multipolygonfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6630 (class 0 OID 0)
-- Dependencies: 640
-- Name: FUNCTION st_ndims(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ndims(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6631 (class 0 OID 0)
-- Dependencies: 749
-- Name: FUNCTION st_node(g public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_node(g public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6632 (class 0 OID 0)
-- Dependencies: 719
-- Name: FUNCTION st_normalize(geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_normalize(geom public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6633 (class 0 OID 0)
-- Dependencies: 712
-- Name: FUNCTION st_npoints(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_npoints(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6634 (class 0 OID 0)
-- Dependencies: 972
-- Name: FUNCTION st_nrings(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_nrings(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6635 (class 0 OID 0)
-- Dependencies: 815
-- Name: FUNCTION st_numcurves(geometry public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numcurves(geometry public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6636 (class 0 OID 0)
-- Dependencies: 369
-- Name: FUNCTION st_numgeometries(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numgeometries(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6637 (class 0 OID 0)
-- Dependencies: 468
-- Name: FUNCTION st_numinteriorring(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numinteriorring(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6638 (class 0 OID 0)
-- Dependencies: 693
-- Name: FUNCTION st_numinteriorrings(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numinteriorrings(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6639 (class 0 OID 0)
-- Dependencies: 253
-- Name: FUNCTION st_numpatches(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numpatches(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6640 (class 0 OID 0)
-- Dependencies: 365
-- Name: FUNCTION st_numpoints(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_numpoints(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6641 (class 0 OID 0)
-- Dependencies: 511
-- Name: FUNCTION st_offsetcurve(line public.geometry, distance double precision, params text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_offsetcurve(line public.geometry, distance double precision, params text) TO drivekeep_app_user;


--
-- TOC entry 6642 (class 0 OID 0)
-- Dependencies: 243
-- Name: FUNCTION st_orderingequals(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_orderingequals(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6643 (class 0 OID 0)
-- Dependencies: 592
-- Name: FUNCTION st_orientedenvelope(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_orientedenvelope(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6644 (class 0 OID 0)
-- Dependencies: 697
-- Name: FUNCTION st_overlaps(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_overlaps(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6645 (class 0 OID 0)
-- Dependencies: 275
-- Name: FUNCTION st_patchn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_patchn(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6646 (class 0 OID 0)
-- Dependencies: 328
-- Name: FUNCTION st_perimeter(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_perimeter(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6647 (class 0 OID 0)
-- Dependencies: 518
-- Name: FUNCTION st_perimeter(geog public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_perimeter(geog public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6648 (class 0 OID 0)
-- Dependencies: 272
-- Name: FUNCTION st_perimeter2d(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_perimeter2d(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6649 (class 0 OID 0)
-- Dependencies: 797
-- Name: FUNCTION st_point(double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6650 (class 0 OID 0)
-- Dependencies: 869
-- Name: FUNCTION st_point(double precision, double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_point(double precision, double precision, srid integer) TO drivekeep_app_user;


--
-- TOC entry 6651 (class 0 OID 0)
-- Dependencies: 984
-- Name: FUNCTION st_pointfromgeohash(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromgeohash(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6652 (class 0 OID 0)
-- Dependencies: 683
-- Name: FUNCTION st_pointfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6653 (class 0 OID 0)
-- Dependencies: 339
-- Name: FUNCTION st_pointfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6654 (class 0 OID 0)
-- Dependencies: 947
-- Name: FUNCTION st_pointfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6655 (class 0 OID 0)
-- Dependencies: 327
-- Name: FUNCTION st_pointfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6656 (class 0 OID 0)
-- Dependencies: 301
-- Name: FUNCTION st_pointinsidecircle(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointinsidecircle(public.geometry, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6657 (class 0 OID 0)
-- Dependencies: 908
-- Name: FUNCTION st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO drivekeep_app_user;


--
-- TOC entry 6658 (class 0 OID 0)
-- Dependencies: 308
-- Name: FUNCTION st_pointn(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointn(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6659 (class 0 OID 0)
-- Dependencies: 297
-- Name: FUNCTION st_pointonsurface(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointonsurface(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6660 (class 0 OID 0)
-- Dependencies: 380
-- Name: FUNCTION st_points(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_points(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6661 (class 0 OID 0)
-- Dependencies: 567
-- Name: FUNCTION st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO drivekeep_app_user;


--
-- TOC entry 6662 (class 0 OID 0)
-- Dependencies: 833
-- Name: FUNCTION st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO drivekeep_app_user;


--
-- TOC entry 6663 (class 0 OID 0)
-- Dependencies: 711
-- Name: FUNCTION st_polyfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6664 (class 0 OID 0)
-- Dependencies: 668
-- Name: FUNCTION st_polyfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6665 (class 0 OID 0)
-- Dependencies: 618
-- Name: FUNCTION st_polyfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6666 (class 0 OID 0)
-- Dependencies: 847
-- Name: FUNCTION st_polyfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polyfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6667 (class 0 OID 0)
-- Dependencies: 312
-- Name: FUNCTION st_polygon(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygon(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6668 (class 0 OID 0)
-- Dependencies: 814
-- Name: FUNCTION st_polygonfromtext(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text) TO drivekeep_app_user;


--
-- TOC entry 6669 (class 0 OID 0)
-- Dependencies: 750
-- Name: FUNCTION st_polygonfromtext(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromtext(text, integer) TO drivekeep_app_user;


--
-- TOC entry 6670 (class 0 OID 0)
-- Dependencies: 402
-- Name: FUNCTION st_polygonfromwkb(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea) TO drivekeep_app_user;


--
-- TOC entry 6671 (class 0 OID 0)
-- Dependencies: 830
-- Name: FUNCTION st_polygonfromwkb(bytea, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO drivekeep_app_user;


--
-- TOC entry 6672 (class 0 OID 0)
-- Dependencies: 386
-- Name: FUNCTION st_polygonize(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6673 (class 0 OID 0)
-- Dependencies: 619
-- Name: FUNCTION st_project(geog public.geography, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geog public.geography, distance double precision, azimuth double precision) TO drivekeep_app_user;


--
-- TOC entry 6674 (class 0 OID 0)
-- Dependencies: 799
-- Name: FUNCTION st_project(geog_from public.geography, geog_to public.geography, distance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geog_from public.geography, geog_to public.geography, distance double precision) TO drivekeep_app_user;


--
-- TOC entry 6675 (class 0 OID 0)
-- Dependencies: 647
-- Name: FUNCTION st_project(geom1 public.geometry, distance double precision, azimuth double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, distance double precision, azimuth double precision) TO drivekeep_app_user;


--
-- TOC entry 6676 (class 0 OID 0)
-- Dependencies: 477
-- Name: FUNCTION st_project(geom1 public.geometry, geom2 public.geometry, distance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_project(geom1 public.geometry, geom2 public.geometry, distance double precision) TO drivekeep_app_user;


--
-- TOC entry 6677 (class 0 OID 0)
-- Dependencies: 252
-- Name: FUNCTION st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_quantizecoordinates(g public.geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO drivekeep_app_user;


--
-- TOC entry 6678 (class 0 OID 0)
-- Dependencies: 789
-- Name: FUNCTION st_reduceprecision(geom public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_reduceprecision(geom public.geometry, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6679 (class 0 OID 0)
-- Dependencies: 534
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6680 (class 0 OID 0)
-- Dependencies: 775
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6681 (class 0 OID 0)
-- Dependencies: 506
-- Name: FUNCTION st_relate(geom1 public.geometry, geom2 public.geometry, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relate(geom1 public.geometry, geom2 public.geometry, text) TO drivekeep_app_user;


--
-- TOC entry 6682 (class 0 OID 0)
-- Dependencies: 409
-- Name: FUNCTION st_relatematch(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_relatematch(text, text) TO drivekeep_app_user;


--
-- TOC entry 6683 (class 0 OID 0)
-- Dependencies: 891
-- Name: FUNCTION st_removeirrelevantpointsforview(public.geometry, public.box2d, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_removeirrelevantpointsforview(public.geometry, public.box2d, boolean) TO drivekeep_app_user;


--
-- TOC entry 6684 (class 0 OID 0)
-- Dependencies: 580
-- Name: FUNCTION st_removepoint(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_removepoint(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6685 (class 0 OID 0)
-- Dependencies: 957
-- Name: FUNCTION st_removerepeatedpoints(geom public.geometry, tolerance double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_removerepeatedpoints(geom public.geometry, tolerance double precision) TO drivekeep_app_user;


--
-- TOC entry 6686 (class 0 OID 0)
-- Dependencies: 568
-- Name: FUNCTION st_removesmallparts(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_removesmallparts(public.geometry, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6687 (class 0 OID 0)
-- Dependencies: 943
-- Name: FUNCTION st_reverse(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_reverse(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6688 (class 0 OID 0)
-- Dependencies: 346
-- Name: FUNCTION st_rotate(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6689 (class 0 OID 0)
-- Dependencies: 295
-- Name: FUNCTION st_rotate(public.geometry, double precision, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6690 (class 0 OID 0)
-- Dependencies: 407
-- Name: FUNCTION st_rotate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotate(public.geometry, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6691 (class 0 OID 0)
-- Dependencies: 422
-- Name: FUNCTION st_rotatex(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotatex(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6692 (class 0 OID 0)
-- Dependencies: 975
-- Name: FUNCTION st_rotatey(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotatey(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6693 (class 0 OID 0)
-- Dependencies: 364
-- Name: FUNCTION st_rotatez(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_rotatez(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6694 (class 0 OID 0)
-- Dependencies: 465
-- Name: FUNCTION st_scale(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6695 (class 0 OID 0)
-- Dependencies: 748
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6696 (class 0 OID 0)
-- Dependencies: 425
-- Name: FUNCTION st_scale(public.geometry, public.geometry, origin public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, public.geometry, origin public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6697 (class 0 OID 0)
-- Dependencies: 492
-- Name: FUNCTION st_scale(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scale(public.geometry, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6698 (class 0 OID 0)
-- Dependencies: 435
-- Name: FUNCTION st_scroll(public.geometry, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_scroll(public.geometry, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6699 (class 0 OID 0)
-- Dependencies: 292
-- Name: FUNCTION st_segmentize(geog public.geography, max_segment_length double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_segmentize(geog public.geography, max_segment_length double precision) TO drivekeep_app_user;


--
-- TOC entry 6700 (class 0 OID 0)
-- Dependencies: 954
-- Name: FUNCTION st_segmentize(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_segmentize(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6701 (class 0 OID 0)
-- Dependencies: 602
-- Name: FUNCTION st_seteffectivearea(public.geometry, double precision, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_seteffectivearea(public.geometry, double precision, integer) TO drivekeep_app_user;


--
-- TOC entry 6702 (class 0 OID 0)
-- Dependencies: 429
-- Name: FUNCTION st_setpoint(public.geometry, integer, public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_setpoint(public.geometry, integer, public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6703 (class 0 OID 0)
-- Dependencies: 520
-- Name: FUNCTION st_setsrid(geog public.geography, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_setsrid(geog public.geography, srid integer) TO drivekeep_app_user;


--
-- TOC entry 6704 (class 0 OID 0)
-- Dependencies: 937
-- Name: FUNCTION st_setsrid(geom public.geometry, srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_setsrid(geom public.geometry, srid integer) TO drivekeep_app_user;


--
-- TOC entry 6705 (class 0 OID 0)
-- Dependencies: 500
-- Name: FUNCTION st_sharedpaths(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_sharedpaths(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6706 (class 0 OID 0)
-- Dependencies: 888
-- Name: FUNCTION st_shiftlongitude(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shiftlongitude(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6707 (class 0 OID 0)
-- Dependencies: 918
-- Name: FUNCTION st_shortestline(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shortestline(text, text) TO drivekeep_app_user;


--
-- TOC entry 6708 (class 0 OID 0)
-- Dependencies: 820
-- Name: FUNCTION st_shortestline(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shortestline(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6709 (class 0 OID 0)
-- Dependencies: 807
-- Name: FUNCTION st_shortestline(public.geography, public.geography, use_spheroid boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_shortestline(public.geography, public.geography, use_spheroid boolean) TO drivekeep_app_user;


--
-- TOC entry 6710 (class 0 OID 0)
-- Dependencies: 884
-- Name: FUNCTION st_simplify(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6711 (class 0 OID 0)
-- Dependencies: 432
-- Name: FUNCTION st_simplify(public.geometry, double precision, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplify(public.geometry, double precision, boolean) TO drivekeep_app_user;


--
-- TOC entry 6712 (class 0 OID 0)
-- Dependencies: 843
-- Name: FUNCTION st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplifypolygonhull(geom public.geometry, vertex_fraction double precision, is_outer boolean) TO drivekeep_app_user;


--
-- TOC entry 6713 (class 0 OID 0)
-- Dependencies: 804
-- Name: FUNCTION st_simplifypreservetopology(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplifypreservetopology(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6714 (class 0 OID 0)
-- Dependencies: 575
-- Name: FUNCTION st_simplifyvw(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_simplifyvw(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6715 (class 0 OID 0)
-- Dependencies: 688
-- Name: FUNCTION st_snap(geom1 public.geometry, geom2 public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snap(geom1 public.geometry, geom2 public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6716 (class 0 OID 0)
-- Dependencies: 927
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6717 (class 0 OID 0)
-- Dependencies: 408
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6718 (class 0 OID 0)
-- Dependencies: 311
-- Name: FUNCTION st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(public.geometry, double precision, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6719 (class 0 OID 0)
-- Dependencies: 881
-- Name: FUNCTION st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_snaptogrid(geom1 public.geometry, geom2 public.geometry, double precision, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6720 (class 0 OID 0)
-- Dependencies: 574
-- Name: FUNCTION st_split(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_split(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6721 (class 0 OID 0)
-- Dependencies: 423
-- Name: FUNCTION st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6722 (class 0 OID 0)
-- Dependencies: 845
-- Name: FUNCTION st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_squaregrid(size double precision, bounds public.geometry, OUT geom public.geometry, OUT i integer, OUT j integer) TO drivekeep_app_user;


--
-- TOC entry 6723 (class 0 OID 0)
-- Dependencies: 480
-- Name: FUNCTION st_srid(geog public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_srid(geog public.geography) TO drivekeep_app_user;


--
-- TOC entry 6724 (class 0 OID 0)
-- Dependencies: 684
-- Name: FUNCTION st_srid(geom public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_srid(geom public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6725 (class 0 OID 0)
-- Dependencies: 608
-- Name: FUNCTION st_startpoint(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_startpoint(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6726 (class 0 OID 0)
-- Dependencies: 476
-- Name: FUNCTION st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_subdivide(geom public.geometry, maxvertices integer, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6727 (class 0 OID 0)
-- Dependencies: 636
-- Name: FUNCTION st_summary(public.geography); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_summary(public.geography) TO drivekeep_app_user;


--
-- TOC entry 6728 (class 0 OID 0)
-- Dependencies: 620
-- Name: FUNCTION st_summary(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_summary(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6729 (class 0 OID 0)
-- Dependencies: 643
-- Name: FUNCTION st_swapordinates(geom public.geometry, ords cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_swapordinates(geom public.geometry, ords cstring) TO drivekeep_app_user;


--
-- TOC entry 6730 (class 0 OID 0)
-- Dependencies: 359
-- Name: FUNCTION st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_symdifference(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6731 (class 0 OID 0)
-- Dependencies: 658
-- Name: FUNCTION st_symmetricdifference(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_symmetricdifference(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6732 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds public.geometry, margin double precision) TO drivekeep_app_user;


--
-- TOC entry 6733 (class 0 OID 0)
-- Dependencies: 352
-- Name: FUNCTION st_touches(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_touches(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6734 (class 0 OID 0)
-- Dependencies: 747
-- Name: FUNCTION st_transform(public.geometry, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(public.geometry, integer) TO drivekeep_app_user;


--
-- TOC entry 6735 (class 0 OID 0)
-- Dependencies: 512
-- Name: FUNCTION st_transform(geom public.geometry, to_proj text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, to_proj text) TO drivekeep_app_user;


--
-- TOC entry 6736 (class 0 OID 0)
-- Dependencies: 644
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_srid integer) TO drivekeep_app_user;


--
-- TOC entry 6737 (class 0 OID 0)
-- Dependencies: 290
-- Name: FUNCTION st_transform(geom public.geometry, from_proj text, to_proj text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transform(geom public.geometry, from_proj text, to_proj text) TO drivekeep_app_user;


--
-- TOC entry 6738 (class 0 OID 0)
-- Dependencies: 239
-- Name: FUNCTION st_transformpipeline(geom public.geometry, pipeline text, to_srid integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transformpipeline(geom public.geometry, pipeline text, to_srid integer) TO drivekeep_app_user;


--
-- TOC entry 6739 (class 0 OID 0)
-- Dependencies: 566
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6740 (class 0 OID 0)
-- Dependencies: 705
-- Name: FUNCTION st_translate(public.geometry, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_translate(public.geometry, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6741 (class 0 OID 0)
-- Dependencies: 945
-- Name: FUNCTION st_transscale(public.geometry, double precision, double precision, double precision, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_transscale(public.geometry, double precision, double precision, double precision, double precision) TO drivekeep_app_user;


--
-- TOC entry 6742 (class 0 OID 0)
-- Dependencies: 496
-- Name: FUNCTION st_triangulatepolygon(g1 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_triangulatepolygon(g1 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6743 (class 0 OID 0)
-- Dependencies: 760
-- Name: FUNCTION st_unaryunion(public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_unaryunion(public.geometry, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6744 (class 0 OID 0)
-- Dependencies: 860
-- Name: FUNCTION st_union(public.geometry[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(public.geometry[]) TO drivekeep_app_user;


--
-- TOC entry 6745 (class 0 OID 0)
-- Dependencies: 342
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6746 (class 0 OID 0)
-- Dependencies: 710
-- Name: FUNCTION st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(geom1 public.geometry, geom2 public.geometry, gridsize double precision) TO drivekeep_app_user;


--
-- TOC entry 6747 (class 0 OID 0)
-- Dependencies: 457
-- Name: FUNCTION st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_voronoilines(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6748 (class 0 OID 0)
-- Dependencies: 880
-- Name: FUNCTION st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_voronoipolygons(g1 public.geometry, tolerance double precision, extend_to public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6749 (class 0 OID 0)
-- Dependencies: 827
-- Name: FUNCTION st_within(geom1 public.geometry, geom2 public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_within(geom1 public.geometry, geom2 public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6750 (class 0 OID 0)
-- Dependencies: 362
-- Name: FUNCTION st_wkbtosql(wkb bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_wkbtosql(wkb bytea) TO drivekeep_app_user;


--
-- TOC entry 6751 (class 0 OID 0)
-- Dependencies: 591
-- Name: FUNCTION st_wkttosql(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_wkttosql(text) TO drivekeep_app_user;


--
-- TOC entry 6752 (class 0 OID 0)
-- Dependencies: 309
-- Name: FUNCTION st_wrapx(geom public.geometry, wrap double precision, move double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_wrapx(geom public.geometry, wrap double precision, move double precision) TO drivekeep_app_user;


--
-- TOC entry 6753 (class 0 OID 0)
-- Dependencies: 866
-- Name: FUNCTION st_x(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_x(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6754 (class 0 OID 0)
-- Dependencies: 902
-- Name: FUNCTION st_xmax(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_xmax(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6755 (class 0 OID 0)
-- Dependencies: 273
-- Name: FUNCTION st_xmin(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_xmin(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6756 (class 0 OID 0)
-- Dependencies: 848
-- Name: FUNCTION st_y(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_y(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6757 (class 0 OID 0)
-- Dependencies: 329
-- Name: FUNCTION st_ymax(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ymax(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6758 (class 0 OID 0)
-- Dependencies: 673
-- Name: FUNCTION st_ymin(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_ymin(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6759 (class 0 OID 0)
-- Dependencies: 660
-- Name: FUNCTION st_z(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_z(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6760 (class 0 OID 0)
-- Dependencies: 980
-- Name: FUNCTION st_zmax(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_zmax(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6761 (class 0 OID 0)
-- Dependencies: 777
-- Name: FUNCTION st_zmflag(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_zmflag(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6762 (class 0 OID 0)
-- Dependencies: 499
-- Name: FUNCTION st_zmin(public.box3d); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_zmin(public.box3d) TO drivekeep_app_user;


--
-- TOC entry 6763 (class 0 OID 0)
-- Dependencies: 573
-- Name: FUNCTION updategeometrysrid(character varying, character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO drivekeep_app_user;


--
-- TOC entry 6764 (class 0 OID 0)
-- Dependencies: 828
-- Name: FUNCTION updategeometrysrid(character varying, character varying, character varying, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO drivekeep_app_user;


--
-- TOC entry 6765 (class 0 OID 0)
-- Dependencies: 353
-- Name: FUNCTION updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO drivekeep_app_user;


--
-- TOC entry 6766 (class 0 OID 0)
-- Dependencies: 1673
-- Name: FUNCTION st_3dextent(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_3dextent(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6767 (class 0 OID 0)
-- Dependencies: 1684
-- Name: FUNCTION st_asflatgeobuf(anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement) TO drivekeep_app_user;


--
-- TOC entry 6768 (class 0 OID 0)
-- Dependencies: 1692
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean) TO drivekeep_app_user;


--
-- TOC entry 6769 (class 0 OID 0)
-- Dependencies: 1693
-- Name: FUNCTION st_asflatgeobuf(anyelement, boolean, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asflatgeobuf(anyelement, boolean, text) TO drivekeep_app_user;


--
-- TOC entry 6770 (class 0 OID 0)
-- Dependencies: 1690
-- Name: FUNCTION st_asgeobuf(anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement) TO drivekeep_app_user;


--
-- TOC entry 6771 (class 0 OID 0)
-- Dependencies: 1691
-- Name: FUNCTION st_asgeobuf(anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asgeobuf(anyelement, text) TO drivekeep_app_user;


--
-- TOC entry 6772 (class 0 OID 0)
-- Dependencies: 1685
-- Name: FUNCTION st_asmvt(anyelement); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement) TO drivekeep_app_user;


--
-- TOC entry 6773 (class 0 OID 0)
-- Dependencies: 1686
-- Name: FUNCTION st_asmvt(anyelement, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text) TO drivekeep_app_user;


--
-- TOC entry 6774 (class 0 OID 0)
-- Dependencies: 1687
-- Name: FUNCTION st_asmvt(anyelement, text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer) TO drivekeep_app_user;


--
-- TOC entry 6775 (class 0 OID 0)
-- Dependencies: 1688
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text) TO drivekeep_app_user;


--
-- TOC entry 6776 (class 0 OID 0)
-- Dependencies: 1689
-- Name: FUNCTION st_asmvt(anyelement, text, integer, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_asmvt(anyelement, text, integer, text, text) TO drivekeep_app_user;


--
-- TOC entry 6777 (class 0 OID 0)
-- Dependencies: 1679
-- Name: FUNCTION st_clusterintersecting(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterintersecting(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6778 (class 0 OID 0)
-- Dependencies: 1680
-- Name: FUNCTION st_clusterwithin(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_clusterwithin(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6779 (class 0 OID 0)
-- Dependencies: 1678
-- Name: FUNCTION st_collect(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_collect(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6780 (class 0 OID 0)
-- Dependencies: 1683
-- Name: FUNCTION st_coverageunion(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_coverageunion(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6781 (class 0 OID 0)
-- Dependencies: 1672
-- Name: FUNCTION st_extent(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_extent(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6782 (class 0 OID 0)
-- Dependencies: 1682
-- Name: FUNCTION st_makeline(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_makeline(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6783 (class 0 OID 0)
-- Dependencies: 1674
-- Name: FUNCTION st_memcollect(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_memcollect(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6784 (class 0 OID 0)
-- Dependencies: 1675
-- Name: FUNCTION st_memunion(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_memunion(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6785 (class 0 OID 0)
-- Dependencies: 1681
-- Name: FUNCTION st_polygonize(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_polygonize(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6786 (class 0 OID 0)
-- Dependencies: 1676
-- Name: FUNCTION st_union(public.geometry); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(public.geometry) TO drivekeep_app_user;


--
-- TOC entry 6787 (class 0 OID 0)
-- Dependencies: 1677
-- Name: FUNCTION st_union(public.geometry, double precision); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.st_union(public.geometry, double precision) TO drivekeep_app_user;


--
-- TOC entry 6788 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE arac; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.arac TO drivekeep_app_user;


--
-- TOC entry 6789 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE fiyatlandirmamodelleri; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.fiyatlandirmamodelleri TO drivekeep_app_user;


--
-- TOC entry 6790 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE kiralama; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.kiralama TO drivekeep_app_user;


--
-- TOC entry 6791 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE kullanici; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.kullanici TO drivekeep_app_user;


--
-- TOC entry 6792 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE aktif_kiralama_ozet; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.aktif_kiralama_ozet TO drivekeep_app_user;


--
-- TOC entry 6794 (class 0 OID 0)
-- Dependencies: 226
-- Name: SEQUENCE arac_arac_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON SEQUENCE public.arac_arac_id_seq TO drivekeep_app_user;


--
-- TOC entry 6795 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE aracturu; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.aracturu TO drivekeep_app_user;


--
-- TOC entry 6797 (class 0 OID 0)
-- Dependencies: 228
-- Name: SEQUENCE aracturu_tur_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON SEQUENCE public.aracturu_tur_id_seq TO drivekeep_app_user;


--
-- TOC entry 6799 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE fiyatlandirmamodelleri_model_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON SEQUENCE public.fiyatlandirmamodelleri_model_id_seq TO drivekeep_app_user;


--
-- TOC entry 6800 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.geography_columns TO drivekeep_app_user;


--
-- TOC entry 6801 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.geometry_columns TO drivekeep_app_user;


--
-- TOC entry 6803 (class 0 OID 0)
-- Dependencies: 232
-- Name: SEQUENCE kiralama_kiralama_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON SEQUENCE public.kiralama_kiralama_id_seq TO drivekeep_app_user;


--
-- TOC entry 6804 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE konumtakip; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.konumtakip TO drivekeep_app_user;


--
-- TOC entry 6806 (class 0 OID 0)
-- Dependencies: 234
-- Name: SEQUENCE konumtakip_kayit_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON SEQUENCE public.konumtakip_kayit_id_seq TO drivekeep_app_user;


--
-- TOC entry 6808 (class 0 OID 0)
-- Dependencies: 236
-- Name: SEQUENCE kullanici_kullanici_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON SEQUENCE public.kullanici_kullanici_id_seq TO drivekeep_app_user;


--
-- TOC entry 6809 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.spatial_ref_sys TO drivekeep_app_user;


--
-- TOC entry 2969 (class 826 OID 34085)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,UPDATE ON TABLES TO drivekeep_app_user;


-- Completed on 2026-06-05 01:52:53

--
-- PostgreSQL database dump complete
--

\unrestrict qpdMm0EbFfkbaHHTe8UiCnlrX9DdFE26e35L3yt09jY3AR6lrghADlEwJJ73hUu

