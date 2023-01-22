---Standard SQL/MM Part: 3 Spatial.
---A. (Oracle) Wykorzystując klauzule CONNECT BY wyświetl hierarchię typu
---ST_GEOMETRY.

select lpad('-',2*(level-1),'|-') || t.owner||'.'||t.type_name||' (FINAL:'||t.final||
', INSTANTIABLE:'||t.instantiable||', ATTRIBUTES:'||t.attributes||', METHODS:'||t.methods||')'
from all_types t
start with t.type_name = 'ST_GEOMETRY'
connect by prior t.type_name = t.supertype_name
and prior t.owner = t.owner;

---B. (Oracle) Wyświetl nazwy metod typu ST_POLYGON.

select distinct m.method_name
from all_type_methods m
where m.type_name like 'ST_POLYGON'
and m.owner = 'MDSYS'"jedrzej wasik" <jedrzej.wasik@studentput.poznan.pl>
order by 1;

---(Oracle) Utwórz tabelę MYST_MAJOR_CITIES o następujących kolumnach:

create table MYST_MAJOR_CITIES(
FIPS_CNTRY VARCHAR(2),
CITY_NAME VARCHAR(40),
STGEOM ST_POINT
)

---Przepisz zawartość tabeli MAJOR_CITIES (znajduje się ona w schemacie
---ZSBD_TOOLS)

INSERT INTO MYST_MAJOR_CITIES
SELECT FIPS_CNTRY, CITY_NAME, ST_Point(GEOM)
FROM MAJOR_CITIES;

SELECT * FROM MYST_MAJOR_CITIES;

---Ćwiczenie 2
---Standard SQL/MM Part: 3 Spatial – konwersja formatów

---Wstaw do tabeli MYST_MAJOR_CITIES informację dotyczącą Szczyrku. Załóż, że
---centrum Szczyrku znajduje się w punkcie o współrzędnych 19.036107;
---49.718655. Wprowadź informację przy wykorzystaniu formatu well-known text
---(WKT).

INSERT INTO MYST_MAJOR_CITIES VALUES
('PL', 'SZCZYRK', TREAT(ST_POINT.FROM_WKT('POINT(19.036107 49.718655)', 8307) AS ST_POINT));


DESCRIBE RIVERS;
SELECT name, treat(ST_POINT.FROM_SDO_GEOM(GEOM) AS ST_GEOMETRY).GET_WKT() FROM rivers;


---Wyświetl definicję przestrzenną wprowadzonego przez Ciebie miasta Szczyrk w
---postaci formatu GML.

SELECT SDO_UTIL.TO_GMLGEOMETRY( ST_POINT.GET_SDO_GEOM(STGEOM)) GML FROM MYST_MAJOR_CITIES WHERE CITY_NAME='SZCZYRK';


---Ćwiczenie 3
---Standard SQL/MM Part: 3 Spatial – pobieranie własności i miar

---Utwórz tabelę MYST_COUNTRY_BOUNDARIES z następującymi atrybutami

CREATE TABLE MYST_COUNTRY_BOUNDARIES
(
    FIPS_CNTRY VARCHAR2(2),
    CNTRY_NAME VARCHAR2(40),
    STGEOM ST_MULTIPOLYGON
);

---Przepisz zawartość tabeli COUNTRY_BOUNDARIES do nowo utworzonej tabeli
---dokonując odpowiednich konwersji (w przypadku DB2 konwersja nie będzie
---potrzebna).

INSERT INTO MYST_COUNTRY_BOUNDARIES
SELECT FIPS_CNTRY, CNTRY_NAME, ST_MULTIPOLYGON(GEOM) FROM COUNTRY_BOUNDARIES;

---Sprawdź jakiego typu i ile obiektów przestrzennych zostało umieszczonych w
---tabeli MYST_COUNTRY_BOUNDARIES

select B.STGEOM.ST_GeometryType() TYPE, count(*) ILE
FROM MYST_COUNTRY_BOUNDARIES B
GROUP BY B.STGEOM.ST_GeometryType()

---D. Sprawdź czy wszystkie definicje przestrzenne uznawane są za proste

select B.STGEOM.ST_ISSIMPLE() isSimple, count(*) ILE
FROM MYST_COUNTRY_BOUNDARIES B
GROUP BY B.STGEOM.ST_ISSIMPLE()

---Ćwiczenie 4
---Standard SQL/MM Part: 3 Spatial – przetwarzanie danych przestrzennych

---A. Sprawdź ile miejscowości (MYST_MAJOR_CITIES) zawiera się w danym państwie
---(MYST_COUNTRY_BOUNDARIES).

SELECT C.CNTRY_NAME, COUNT(*) 
FROM MYST_COUNTRY_BOUNDARIES C, MYST_MAJOR_CITIES M
WHERE C.STGEOM.ST_CONTAINS(M.STGEOM) = 1
GROUP BY C.CNTRY_NAME
ORDER BY 1;

---B. Znajdź te państwa, które graniczą z Czechami.

SELECT A.CNTRY_NAME
FROM MYST_COUNTRY_BOUNDARIES A, MYST_COUNTRY_BOUNDARIES B 
WHERE A.STGEOM.ST_TOUCHES(B.STGEOM) = 1
AND B.CNTRY_NAME = 'Czech Republic';


---C. Znajdź nazwy tych rzek, które przecinają granicę Czech – wykorzystaj tabelę
---RIVERS (w przypadku bazy Oracle wykorzystaj także konstruktor typu
---ST_LINESTRING)
describe rivers

SELECT DISTINCT R.NAME
FROM MYST_COUNTRY_BOUNDARIES A, RIVERS R 
WHERE A.STGEOM.ST_CROSSES(ST_LINESTRING(R.GEOM)) = 1
AND A.CNTRY_NAME = 'Czech Republic'

---D. Sprawdź, jaka powierzchnia jest Czech i Słowacji połączonych w jeden obiekt
---przestrzenny

SELECT TREAT(A.STGEOM.ST_UNION(B.STGEOM) as ST_POLYGON).ST_AREA() CZECHOSLOWACJA
FROM MYST_COUNTRY_BOUNDARIES A, MYST_COUNTRY_BOUNDARIES B
where A.CNTRY_NAME = 'Czech Republic'
and B.CNTRY_NAME = 'Slovakia';

---E. Sprawdź jakiego typu obiektem są Węgry z "wykrojonym" Balatonem –
---wykorzystaj tabelę WATER_BODIES.

select TREAT(B.STGEOM.ST_DIFFERENCE(ST_GEOMETRY(W.GEOM)) as ST_POLYGON).ST_GeometryType() WEGRY_BEZ,
B.STGEOM.ST_AREA(),
ROUND(TREAT(B.STGEOM.ST_DIFFERENCE(ST_GEOMETRY(W.GEOM)) as ST_POLYGON).ST_GeometryType()
/ B.STGEOM.ST_AREA(),2)
from MYST_COUNTRY_BOUNDARIES B, WATER_BODIES W
where B.CNTRY_NAME = 'Hungary'
and W.name = 'Balaton';

---Ćwiczenie 5
---Standard SQL/MM Part: 3 Spatial – indeksowanie i przetwarzanie przy
---użyciu operatorów SDO_NN i SDO_WITHIN_DISTANCE.
---Uwaga! Całe ćwiczenie dotyczy tylko bazy danych Oracle.

---A. (Oracle) Wykorzystując operator SDO_WITHIN_DISTANCE znajdź liczbę
---miejscowości oddalonych od terytorium Polski nie więcej niż 100 km. (wykorzystaj
---tabele MYST_MAJOR_CITIES i MYST_COUNTRY_BOUNDARIES). Obejrzyj plan
---wykonania zapytania. (Uwaga: We wcześniejszych wersjach Oracle użycie tych
---operatorów nawet dla standardowych typów SQL/MM było możliwe tylko z pomocą
---indeksu przestrzennego. Bez niego zapytanie kończyło się błędem „ORA-13226:
---interfejs nie jest obsługiwany bez indeksu przestrzennego”.

EXPLAIN PLAN FOR
SELECT count(CITY_NAME)
FROM MYST_MAJOR_CITIES M, MYST_COUNTRY_BOUNDARIES C
WHERE CNTRY_NAME = 'Poland'
AND SDO_WITHIN_DISTANCE(C.STGEOM,M.STGEOM, 'distance=100 unit=km') = 'TRUE'

---B. (Oracle) Zarejestruj metadane dotyczące stworzonych przez Ciebie tabeli
---MYST_MAJOR_CITIES i/lub MYST_COUNTRY_BOUNDARIES.

INSERT INTO USER_SDO_GEOM_METADATA
SELECT 'MYST_MAJOR_CITIES', 'STGEOM', T.DIMINFO, T.SRID
FROM   ALL_SDO_GEOM_METADATA T WHERE  T.TABLE_NAME = 'MAJOR_CITIES';

INSERT INTO USER_SDO_GEOM_METADATA
SELECT 'MYST_COUNTRY_BOUNDARIES', 'STGEOM', T.DIMINFO, T.SRID
FROM   ALL_SDO_GEOM_METADATA T WHERE  T.TABLE_NAME = 'COUNTRY_BOUNDARIES';

---C. (Oracle) Utwórz na tabelach MYST_MAJOR_CITIES i/lub
---MYST_COUNTRY_BOUNDARIES indeks R-drzewo.

CREATE INDEX MYST_MAJOR_CITIES_IDX ON MYST_MAJOR_CITIES(STGEOM) INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
CREATE INDEX MYST_COUNTRY_BOUNDARIES_IDX ON myst_country_boundaries(STGEOM) INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;

---D. (Oracle) Ponownie znajdź liczbę miejscowości oddalonych od terytorium Polski
---nie więcej niż 100 km. Sprawdź jednocześnie, czy założone przez Ciebie indeksy
---są wykorzystywane wyświetlając plan wykonania zapytania.

EXPLAIN PLAN FOR 
SELECT count(CITY_NAME)
FROM MYST_MAJOR_CITIES M, MYST_COUNTRY_BOUNDARIES C
WHERE CNTRY_NAME = 'Poland'
AND SDO_WITHIN_DISTANCE(C.STGEOM,M.STGEOM, 'distance=100 unit=km') = 'TRUE'

SELECT plan_table_output FROM table(dbms_xplan.display('plan_table', null, 'basic'));