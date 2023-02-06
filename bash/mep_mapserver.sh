#!/bin/bash

# installer mapserver
sudo apt install cgi-mapserver mapserver-bin

# activer le module cgi du serveur web apache
sudo a2enmod cgi 

# puis dans l’ordre
sudo a2enmod authnz_fcgi

# redémarrage du service backend apache2
sudo systemctl restart apache2.service

# taper ensuite dans la barre d’adresse URL
# localhost/cgi-bin/mapserv
# si vous obtenez le message suivant:
# No query information to decode. QUERY_STRING is set, but empty. 
# votre installation mapserver a bien réussi





































