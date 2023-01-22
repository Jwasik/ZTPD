--1. Utwórz w swoim schemacie tabelę MOVIES o poniższej strukturze:
CREATE TABLE movies
(
    ID        NUMBER(12) PRIMARY KEY,
    TITLE     VARCHAR2(400) NOT NULL,
    CATEGORY  VARCHAR2(50),
    YEAR      CHAR(4),
    CAST      VARCHAR2(4000),
    DIRECTOR  VARCHAR2(4000),
    STORY     VARCHAR2(4000),
    PRICE     NUMBER(5, 2),
    COVER     BLOB,
    MIME_TYPE VARCHAR2(50)
);


--2. Wstaw do tabeli MOVIES informacje pobrane z tabel DESCRIPTIONS i COVERS
/*znajdujących się w schemacie wskazanym przez prowadzącego. Zastosuj do tego celu
polecenie INSERT ... SELECT..., zwracając uwagę na to, że nie dla wszystkich filmów są
dostępne okładki (Wskazówka: wykorzystaj połączenie zewnętrzne).*/

INSERT INTO movies (id, title, category, year, cast, director, story, price, cover, mime_type)
SELECT d.id,
       d.title,
       d.category,
       TRIM(to_char(d.year, '9999')),
       d.cast,
       d.director,
       d.story,
       d.price,
       c.image,
       c.mime_type
FROM descriptions d
         FULL OUTER JOIN covers c on d.id = c.movie_id;


-- 3. Sprawdź zapytaniem SQL do tabeli MOVIES, które filmy nie mają okładek.
SELECT id, title
FROM movies
WHERE cover IS NULL;


-- 4. Dla filmów, które mają okładki odczytaj rozmiar obrazka w bajtach.

SELECT id, title, DBMS_LOB.GETLENGTH(cover) AS filesize
FROM movies
WHERE cover IS NOT NULL;


-- 5. Sprawdź co się stanie gdy zostanie dokonana próba odczytu rozmiaru obrazków dla
-- filmów, które nie posiadają okładek w tabeli MOVIES.

SELECT id, title, DBMS_LOB.GETLENGTH(cover) AS filesize
FROM movies
WHERE cover IS NULL;


-- 6. Brakujące okładki zostały umieszczone w jednym z katalogów systemu plików serwera
/*bazy danych w plikach eagles.jpg i escape.jpg. Sprawdź jakie obiekty DIRECTORY są
dostępne i zawartość jakich katalogów udostępniają. Zapytaj prowadzącego który katalog
zawiera potrzebne pliki.*/

SELECT directory_name, directory_path
FROM all_directories;


-- 7. Zmodyfikuj okładkę filmu o identyfikatorze 66 w tabeli MOVIES na pusty obiekt BLOB
/*(lokalizator bez wartości), a jako typ MIME (w przeznaczonej do tego celu kolumnie tabeli)
podaj: image/jpeg. Zatwierdź transakcję.*/

UPDATE movies
SET cover     = EMPTY_BLOB(),
    mime_type = 'image/jpeg'
WHERE id = 66;

COMMIT;


-- 8. Odczytaj z tabeli MOVIES rozmiar obrazków dla filmów o identyfikatorach 65 i 66.
SELECT id, title, DBMS_LOB.GETLENGTH(cover) AS filesize
FROM movies
WHERE id IN (65, 66);


-- 9. Napisz program w formie anonimowego bloku PL/SQL, który dla filmu o identyfikatorze
/*66 przekopiuje binarną zawartość obrazka z pliku escape.jpg znajdującego się w katalogu
systemu plików serwera (za pośrednictwem obiektu BFILE) do pustego w tej chwili obiektu
BLOB w tabeli MOVIES. Wykorzystaj poniższy schemat postępowania:

1) Zadeklaruj w programie zmienną typu BFILE i zwiąż ją z plikiem okładki
w katalogu na serwerze.
2) Odczytaj z tabeli MOVIES pusty obiekt BLOB do zmiennej (nie zapomnij
o klauzuli zakładającej blokadę na wierszu zawierającym obiekt BLOB,
który będzie modyfikowany).
3) Przekopiuj zawartość binarną z BFILE do BLOB
(nie zapominając o otwarciu i zamknięciu pliku BFILE!).
4) Zatwierdź transakcję.*/

DECLARE
    cover_file BFILE := BFILENAME('ZSBD_DIR', 'escape.jpg');
    cover_blob BLOB;
BEGIN
    SELECT cover
    INTO cover_blob
    FROM movies
    WHERE id = 66
        FOR UPDATE;
    DBMS_LOB.FILEOPEN(cover_file, DBMS_LOB.file_readonly);
    DBMS_LOB.LOADFROMFILE(cover_blob, cover_file, DBMS_LOB.GETLENGTH(cover_file));
    DBMS_LOB.FILECLOSE(cover_file);
    COMMIT;
END;


-- 10. Utwórz tabelę TEMP_COVERS o poniższej strukturze:
CREATE TABLE temp_covers
(
    movie_id  NUMBER(12),
    image     BFILE,
    mime_type VARCHAR2(50)
);


-- 11. Wstaw do tabeli TEMP_COVERS obrazek z pliku eagles.jpg z udostępnionego katalogu.
/*Nadaj mu identyfikator filmu, którego jest okładką (65). Jako typ MIME podaj: image/jpeg.
Zatwierdź transakcję.*/

INSERT INTO temp_covers
VALUES (65, BFILENAME('ZSBD_DIR', 'eagles.jpg'), 'image/jpeg');

COMMIT;


-- 12. Odczytaj rozmiar w bajtach dla obrazka załadowanego jako BFILE.
SELECT movie_id, DBMS_LOB.GETLENGTH(image) AS filesize
FROM temp_covers;


-- 13. Napisz program w formie anonimowego bloku PL/SQL, który dla filmu o identyfikatorze
/*65 utworzy obiekt BLOB, przekopiuje do niego binarną zawartość okładki BFILE z tabeli
TEMP_COVERS i umieści BLOB w odpowiednim wierszu tabeli MOVIES. Wykorzystaj
poniższy schemat postępowania:
1) Odczytaj lokalizator BFILE i informację o typie MIME obrazka z tabeli
TEMP_COVERS do zmiennych w programie.
2) Utwórz tymczasowy obiekt LOB.
3) Przekopiuj do niego zawartość binarną z BFILE
(nie zapominając o otwarciu i zamknięciu pliku!).
4) Zapisz tymczasowy LOB do tabeli MOVIES poleceniem UPDATE, jednocześnie
ustawiając typ MIME na odczytany z tabeli TEMP_COVERS.
5) Zwolnij tymczasowy LOB.
6) Zatwierdź transakcję.*/

DECLARE
    cover_blob     blob;
    cover_file     BFILE;
    cover_mimetype VARCHAR2(50);
BEGIN
    SELECT image, mime_type
    INTO cover_file, cover_mimetype
    FROM temp_covers
    WHERE movie_id = 65;
    DBMS_LOB.FILEOPEN(cover_file, DBMS_LOB.file_readonly);
    DBMS_LOB.CREATETEMPORARY(cover_blob, TRUE);
    DBMS_LOB.LOADFROMFILE(cover_blob, cover_file, DBMS_LOB.GETLENGTH(cover_file));
    DBMS_LOB.FILECLOSE(cover_file);
    update movies
    set cover     = cover_blob,
        mime_type = cover_mimetype
    where id = 65;
    DBMS_LOB.FREETEMPORARY(cover_blob);
    COMMIT;
END;


-- 14. Odczytaj rozmiar w bajtach dla okładek filmów 65 i 66 z tabeli MOVIES
SELECT id, DBMS_LOB.GETLENGTH(cover) AS filesize
FROM movies
WHERE id IN (65, 66);


-- 15. Usuń tabele MOVIES i TEMP_COVERS.
DROP TABLE movies;
DROP TABLE temp_covers;