-- 1. Utwórz w swoim schemacie tabelę DOKUMENTY o poniższej strukturze:


CREATE TABLE dokumenty(
ID NUMBER(12) PRIMARY KEY,
DOKUMENT CLOB);

-- 2. Wstaw do tabeli DOKUMENTY dokument utworzony przez konkatenację 10000 kopii
/*tekstu 'Oto tekst. ' nadając mu ID = 1 (Wskazówka: wykorzystaj anonimowy blok kodu
PL/SQL).*/

DECLARE 
counter NUMBER := 0;
tekst CLOB := '';
BEGIN
    LOOP
        counter := counter + 1;
        tekst := CONCAT(tekst,'Oto tekst. ');
        
        IF counter > 10000 THEN
            EXIT;
        END IF;
    END LOOP;
    INSERT INTO dokumenty values(1,tekst);
END;

SELECT count(*) FROM dokumenty;

-- 3. Wykonaj poniższe zapytania:
/*a) odczyt całej zawartości tabeli DOKUMENTY
b) odczyt treści dokumentu po zamianie na wielkie litery
c) odczyt rozmiaru dokumentu funkcją LENGTH
d) odczyt rozmiaru dokumentu odpowiednią funkcją z pakietu DBMS_LOB
e) odczyt 1000 znaków dokumentu począwszy od znaku na pozycji 5 funkcją SUBSTR
f) odczyt 1000 znaków dokumentu począwszy od znaku na pozycji 5 odpowiednią funkcją
z pakietu DBMS_LOB*/

SELECT * FROM dokumenty;

SELECT UPPER(DOKUMENT) FROM dokumenty;

SELECT LENGTH(DOKUMENT) FROM dokumenty;

SELECT dbms_lob.getlength(dokument) from dokumenty;

SELECT dbms_lob.substr(dokument,1000,5) from dokumenty;

-- 4. Wstaw do tabeli drugi dokument jako pusty obiekt CLOB nadając mu ID = 2
INSERT INTO dokumenty VALUES(2,'');
-- 5. Wstaw do tabeli trzeci dokument jako NULL nadając mu ID = 3. Zatwierdź transakcję.
INSERT INTO dokumenty VALUES(3,NULL);
COMMIT;

-- 6. Sprawdź jaki będzie efekt zapytań z punktu 3 dla wszystkich trzech dokumentów.

-- 7. W jednym z katalogów systemu plików serwera bazy danych w pliku dokument.txt
/*znajduje się tekst, który w dalszej części ćwiczenia umieścimy jako treść drugiego i trzeciego
dokumentu w tabeli DOKUMENTY. Sprawdź jakie obiekty DIRECTORY są dostępne
i zawartość jakich katalogów udostępniają. Jeśli dostępny jest więcej niż jeden katalog,
zapytaj prowadzącego który katalog zawiera potrzebny plik*/

SELECT DIRECTORY_NAME,DIRECTORY_PATH FROM ALL_DIRECTORIES;

-- 8. Napisz program w formie anonimowego bloku PL/SQL, który do dokumentu
/*o identyfikatorze 2 przekopiuje tekstową zawartość pliku dokument.txt znajdującego się
w katalogu systemu plików serwera (za pośrednictwem obiektu BFILE) do pustego w tej
chwili obiektu CLOB w tabeli DOKUMENTY. Wykorzystaj poniższy schemat postępowania:
1) Zadeklaruj w programie zmienną typu BFILE i zwiąż ją z plikiem tekstowym
w katalogu na serwerze.
2) Odczytaj z tabeli DOKUMENTY pusty obiekt CLOB do zmiennej (nie zapomnij
o klauzuli zakładającej blokadę na wierszu zawierającym obiekt CLOB,
który będzie modyfikowany).
3) Przekopiuj zawartość z BFILE do CLOB procedurą LOADCLOBFROMFILE
z pakietu DBMS_LOB (nie zapominając o otwarciu i zamknięciu pliku BFILE!).
Wskazówki: Pamiętaj aby parametry przekazywane w trybie IN OUT i OUT 
przekazać jako zmienne. Wartości parametrów określających identyfikator zestawu
znaków źródła i kontekst językowy ustaw na 0. Wartość 0 identyfikatora zestawu
znaków źródła oznacza że jest on taki jak w bazie danych dla wykorzystywanego typu
dużego obiektu tekstowego.
4) Zatwierdź transakcję.
5) Wyświetl na konsoli status operacji kopiowania.*/

DECLARE
    lobc CLOB;
    fils BFILE := BFILENAME('ZSBD_DIR','dokument.txt');
BEGIN
    INSERT INTO dokumenty values(2, EMPTY_CLOB());
    
    SELECT dokument INTO lobc from dokumenty WHERE id=2 FOR UPDATE;

    DBMS_LOB.fileopen(fils, DBMS_LOB.file_readonly);
    DBMS_LOB.LOADFROMFILE(lobc, fils, DBMS_LOB.GETLENGTH(fils));
    DBMS_LOB.FILECLOSE(fils);
    COMMIT;
END;

SELECT * FROM dokumenty WHERE ID=2;

-- 9. Do dokumentu o identyfikatorze 3 przekopiuj tekstową zawartość pliku dokument.txt
/*znajdującego się w katalogu systemu plików serwera (za pośrednictwem obiektu BFILE), tym
razem nie korzystając z PL/SQL, a ze zwykłego polecenia UPDATE z poziomu SQL.
Wskazówka: Od wersji Oracle 12.2 funkcje TO_BLOB i TO_CLOB zostały rozszerzone o
obsługę parametru typu BFILE.
(https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/TO_CLOB-bfileblob.html)*/

UPDATE dokumenty
SET dokument = TO_CLOB(BFILENAME('ZSBD_DIR','dokument.txt'),873)
WHERE ID=3;

-- 10. Odczytaj zawartość tabeli DOKUMENTY.
SELECT * FROM dokumenty;
-- 11. Odczytaj rozmiar wszystkich dokumentów z tabeli DOKUMENTY.
SELECT sum(dbms_lob.getlength(dokument)) from dokumenty;
-- 12. Usuń tabelę DOKUMENTY.
DROP TABLE dokumenty;
-- 13. Zaimplementuj w PL/SQL procedurę CLOB_CENSOR, która w podanym jako pierwszy
/*parametr dużym obiekcie CLOB zastąpi wszystkie wystąpienia tekstu podanego jako drugi
parametr (typu VARCHAR2) kropkami, tak aby każdej zastępowanej literze odpowiadała
jedna kropka.
Wskazówka: Nie korzystaj z funkcji REPLACE (tylko z funkcji INSTR i procedury WRITE
z pakietu DBMS_LOB), tak aby procedura była zgodna z wcześniejszymi wersjami Oracle,
w których funkcja REPLACE była ograniczona do tekstów, których długość nie przekraczała
limitu dla VARCHAR2.*/

CREATE OR REPLACE PROCEDURE CLOB_CENSOR
(
first_arg IN OUT CLOB, 
second_arg IN varchar
) IS
    position number;
    replacement varchar(100) := '..............................................................................';
BEGIN
    LOOP
        position := DBMS_LOB.INSTR(first_arg, second_arg);        
        IF position=0 THEN
            EXIT;
        END IF;
        DBMS_LOB.WRITE(first_arg, length(second_arg), position, replacement);
    END LOOP;
END;

-- 14. Utwórz w swoim schemacie kopię tabeli ZSBD_TOOLS.BIOGRAPHIES i przetestuj
-- swoją procedurę zastępując nazwisko „Cimrman” kropkami w biografii Jary Cimrmana.

CREATE TABLE biographies2
AS SELECT * FROM ZSBD_TOOLS.BIOGRAPHIES;

SELECT * FROM biographies2;

DECLARE
    biography clob;
BEGIN
    SELECT BIO INTO biography FROM biographies2 FOR UPDATE;
    CLOB_CENSOR(biography, 'Cimrman');
    COMMIT;
END;

-- 15. Usuń kopię tabeli BIOGRAPHIES ze swojego schematu.
DROP biographies2;