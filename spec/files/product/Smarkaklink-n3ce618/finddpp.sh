#!/bin/sh

cd ../../../../../shg_highway

rake shg:dpp_pledge RAILS_ENV=test PRODUCTID=3c-97-0e-b9-cd-98 >|../shg_mud_supervisor/spec/files/product/Smarkaklink-n3ce618/dpp1.txt
