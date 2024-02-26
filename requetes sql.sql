use dataimmo;

select * from region;

select * from commune limit 0,35000;
select * from bien limit 0,35000;
select * from vente limit 0,35000;




-- 1. Nombre total d’appartements vendus au 1er semestre 2020.
SELECT count(id_bien) AS Nombre_appartement_vendu 
	FROM vente JOIN bien USING(id_bien) 
		WHERE type_local = 'Appartement' AND date_vente >='2020-01-01' AND date_vente <='2020-06-30';  


-- 2. Le nombre de ventes d’appartement par région pour le 1er semestre 2020.
SELECT count(id_vente) Nombre_ventes_par_region, region Region 
	FROM vente JOIN bien USING(id_bien) JOIN commune USING(id_codedep_codecommune) JOIN region USING(id_region) 
               WHERE type_local LIKE 'Appartement' 
					AND date_vente >='2020-01-01' AND date_vente <='2020-06-30' 
						GROUP BY region ORDER BY Nombre_ventes_par_region desc; 
                
                
-- 3. Proportion des ventes d’appartements par le nombre de pièces.
SELECT total_pieces 'Nombre de pièces', ROUND(COUNT(*)*100/ (Select COUNT(id_vente) Total 
				FROM vente JOIN bien USING(id_bien) WHERE type_local = 'Appartement'),2) AS 'Proportion de ventes appartements' 
    FROM bien JOIN vente USING(id_bien) 
		WHERE type_local = 'Appartement'
				GROUP BY total_pieces ORDER BY total_pieces ;


-- 4. Liste des 10 départements où le prix du mètre carré est le plus élevé.
SELECT code_departement Département, round(AVG(valeur_fonciere/surface_carrez),2) Prix_du_metre_carré 
	FROM commune JOIN bien USING(id_codedep_codecommune) JOIN vente USING(id_bien)
			WHERE surface_carrez <> 0 GROUP BY code_departement
				ORDER BY Prix_du_metre_carré DESC LIMIT 10; 


-- 5. Prix moyen du mètre carré d’une maison en Île-de-France.
SELECT round(AVG((valeur_fonciere/surface_carrez)),2) 'Prix moyen du metre carré maison Ile de France' 
	FROM vente JOIN bien USING(id_bien) JOIN commune USING(id_codedep_codecommune) JOIN region USING(id_region)
				WHERE type_local = 'Appartement' AND region = 'Ile-de-France' AND surface_carrez <> 0 ;   


-- 6. Liste des 10 appartements les plus chers avec la région et le nombre de mètres carrés.
SELECT region Région, id_bien, code_departement Département, round(surface_carrez) as 'Surface Appartement', valeur_fonciere as 'Valeur Appartement' 
		FROM bien JOIN vente USING(id_bien) JOIN commune USING(id_codedep_codecommune) JOIN region USING(id_region)
                WHERE type_local = 'Appartement' ORDER BY valeur_fonciere DESC LIMIT 10;
 
 
-- 7. Taux d’évolution du nombre de ventes entre le premier et le second trimestre de 2020.
WITH maCTE1 AS ( 
	SELECT count(*) AS Nbdeuxiemetrimestre 
		FROM bien JOIN vente USING(id_bien) 
			WHERE date_vente > '2020-03-31' AND date_vente <='2020-06-30' ) 
, maCTE2 AS ( 
	SELECT count(*) AS Nbpremiertrimestre 
		FROM bien JOIN vente USING(id_bien) 
			WHERE date_vente <='2020-03-31' )

SELECT round(((Nbdeuxiemetrimestre-Nbpremiertrimestre)/Nbpremiertrimestre)*100,2) AS 'Taux évolution nombre ventes entre premier et second trimestre'
	FROM maCTE1, maCTE2;


-- 8. Le classement des régions par rapport au prix au mètre carré des appartement de plus de 4 pièces.
SELECT region AS Region, round(AVG(valeur_fonciere/surface_carrez)) AS Prix_metre_carré 
	FROM bien JOIN vente USING(id_bien) JOIN commune USING(id_codedep_codecommune) JOIN region USING(id_region) 
			WHERE total_pieces > 4 AND surface_carrez <> 0 AND type_local = 'Appartement' 
				GROUP BY region 
					ORDER BY Prix_metre_carré DESC; 
    
    
-- 9. Liste des communes ayant eu au moins 50 ventes au 1er trimestre
SELECT count(id_vente) Nombre_vente, nom_commune Commune 
	FROM vente JOIN bien USING(id_bien) JOIN commune USING(id_codedep_codecommune)  
		WHERE date_vente <='2020-03-31'
			GROUP BY Commune HAVING Nombre_vente >= 50 
				ORDER BY Nombre_vente DESC ; 
    
    
-- 10. Différence en pourcentage du prix au mètre carré entre un appartement de 2 pièces et un appartement de 3 pièces.
WITH maCTE1 AS ( 
	SELECT avg(valeur_fonciere/surface_carrez) AS Prix_metre_carre_deux_pieces 
		FROM vente JOIN bien USING(id_bien) 
			WHERE total_pieces = 2 AND type_local = 'Appartement' and surface_carrez <> 0 ) 
, maCTE2 AS ( 
	SELECT avg(valeur_fonciere/surface_carrez) AS Prix_metre_carre_trois_pieces 
		FROM vente JOIN bien USING(id_bien) 
			WHERE total_pieces = 3 AND type_local = 'Appartement' and surface_carrez <> 0 )
            
SELECT round(((Prix_metre_carre_trois_pieces-Prix_metre_carre_deux_pieces)/Prix_metre_carre_deux_pieces)*100,2) 
	AS 'Taux évolution du prix au metre carré entre appartement de 2 et de 3 pièces'
		FROM maCTE1, maCTE2;

        
-- 11. Les moyennes de valeurs foncières pour le top 3 des communes des départements 6, 13, 33, 59 et 69.
WITH table_1 AS (
	SELECT ROUND(AVG(v.valeur_fonciere)) Moyenne_fonciere, c.nom_commune Nom_Commune, c.code_departement Code_Departement,
		RANK() OVER(PARTITION BY c.code_departement ORDER BY ROUND(AVG(v.valeur_fonciere)) desc) AS nrlignes
			FROM bien AS b JOIN commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
					JOIN vente AS v ON b.id_bien = v.id_bien
			WHERE c.code_departement IN ('06','13','33','59','69') AND v.valeur_fonciere > 0
				GROUP BY 3, 2 
					ORDER BY 3, nrlignes) 
SELECT * FROM table_1 WHERE nrlignes < 4; 




-- 12. Les 20 communes avec le plus de transactions pour 1000 habitants pour les communes qui dépassent les 10 000 habitants.
WITH maCTE_trans AS ( 
	SELECT nom_commune, round(AVG(population),2) AS pop, count(id_vente) AS nb_transaction
		FROM vente JOIN bien ON vente.id_bien=bien.id_bien JOIN commune ON bien.id_codedep_codecommune=commune.id_codedep_codecommune
			WHERE population > 10000 
				GROUP BY nom_commune)
SELECT nom_commune AS Commune, round((nb_transaction/pop)*1000,2) AS Transactions 
  FROM maCTE_trans ORDER BY Transactions DESC LIMIT 20;
  
  
  
  