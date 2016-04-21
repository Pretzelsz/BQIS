# BQIS

TO RUN:

1) Import this into your rasberry pi, keep the folder structure intact
2) install bluez-5.18 onto your pi
2.1) DO NOT POWER ON YOUR BEACON YET! 
3) Run start_ibeacon_server.sh in terminal 
4) Navigate into the ibeacon_client folder
5) launch ibeacon_client.pde in proccessing, and hit run when prompted at the top of the screen
6) Now you may plug in your beacon


------CHANGES------

- if you wish to have an image instead of a dot, place the image in /ibeacon_client/data, then comment the elipse on line 50, and uncomment the image on line 51.
-  be sure to navigate to the correct image by editing the path on line 39. 
