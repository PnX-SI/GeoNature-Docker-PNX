    DROP TABLE IF EXISTS taxonomie.import_cd_nom_replace;
    CREATE TABLE taxonomie.import_cd_nom_replace (cd_nom INTEGER, cd_nom_replace INTEGER);
    COPY taxonomie.import_cd_nom_replace (cd_nom, cd_nom_replace) FROM '/backup/missing_taxons.csv' WITH DELIMITER ';';

    INSERT INTO TAXONOMIE.TAXREF (cd_nom)
    SELECT cd_nom_replace
    FROM taxonomie.import_cd_nom_replace r
    LEFT JOIN TAXONOMIE.TAXREF T ON t.CD_NOM = r.cd_nom_replace
    WHERE t.cd_nom IS NULL
    ON CONFLICT DO NOTHING
    ;


    UPDATE taxonomie.bib_noms t
        SET CD_NOM = r.cd_nom_replace
        FROM taxonomie.IMPORT_CD_NOM_REPLACE r
        LEFT JOIN taxonomie.bib_noms b2 ON b2.cd_nom = r.cd_nom_replace
        WHERE r.cd_nom = t.cd_nom AND b2.cd_nom IS NULL
    ;

    UPDATE taxonomie.cor_nom_liste c
    SET id_nom = br.id_nom
    FROM taxonomie.IMPORT_CD_NOM_REPLACE r
    LEFT JOIN taxonomie.bib_noms br ON r.cd_nom_replace = br.cd_nom
    JOIN taxonomie.bib_noms b ON b.cd_nom = r.cd_nom
    WHERE br.cd_nom IS NULL and b.id_nom = c.id_nom
    ;

    DELETE FROM taxonomie.cor_nom_liste c
    USING taxonomie.IMPORT_CD_NOM_REPLACE r
    JOIN taxonomie.bib_noms b ON b.cd_nom = r.cd_nom
    WHERE c.id_nom = b.id_nom
    ;

    DELETE FROM taxonomie.bib_noms b
    USING taxonomie.IMPORT_CD_NOM_REPLACE r
    WHERE b.cd_nom = r.cd_nom
    ;

    UPDATE pr_occtax.t_occurrences_occtax t
        SET CD_NOM = r.cd_nom_replace
        FROM taxonomie.IMPORT_CD_NOM_REPLACE r
        WHERE r.cd_nom = t.cd_nom
        ;

    UPDATE GN_SYNTHESE.SYNTHESE  t
        SET CD_NOM = r.cd_nom_replace
        FROM taxonomie.IMPORT_CD_NOM_REPLACE r
        WHERE r.cd_nom = t.cd_nom
    ;
