#Etape 1:
Lancer le conteneur docker. Pour cela vous devez avoir docker et docker compose installé (docker --version et docker compose --version pour vérifier).
Ensuite lancer le fichier de script situer dans le repertoire db. C'est fichier de script lancer conteneur automatiquement.
Il y a une fichier .bat si vous utilisez Windows et un fichier .sh si vous utilisez Linux

#Etape 2:
Lancer le fichier de script python situé à la racine du projet. Il ce peut que vous deviez installer des dépandances via pip.
Ce processus peut prendre beaucoup de temps

 ## Désormais tout est initialiser et vous pouvez lancer les commandes suivantes pour entrer des commandes dans la base de donnée
 
 # Pour vous connecter via les lignes de commandes au conteneur docker
 docker exec -it postgres /bin/bash

 # Pour lancer le terminal pour postgres
  psql -U API_ADMIN -d DATA_BASE_API
