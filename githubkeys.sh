# Add public key to authorized keys
echo Which Github Username do you want to add to authorized keys?     
read ghuser 
url_request=("https://github.com/")
url_ghuser=($ghuser)
url_remainder=(".keys")
url+=("${url_request[@]}""${url_ghuser[@]}""${url_remainder[@]}")
#echo $url
touch ~/.ssh/authorized_keys
curl $url >> ~/.ssh/authorized_keys
