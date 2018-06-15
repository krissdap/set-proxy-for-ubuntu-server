#!/bin/bash

# Step 1: Get proxy server configuration. Proxy name (or IP), username (optional), and password (optional)
echo "Set proxy server for apt, wget, and more"
echo "Please enter your proxy url"
read proxy
echo "Please enter username for proxy (leave as blank if no authentication needed)"
read username
if [ -n "$username" ]
then
	echo "Please enter password for proxy (leave as blank if no password needed)"
	read -s password
	esc_username=${username/@/%40}
fi

# Step 2: Set configuration for each program

# http_proxy variable in /etc/environment
echo http_proxy="http://$esc_username:$password@$proxy" | sudo tee -a /etc/environment
echo https_proxy="http://$esc_username:$password@$proxy" | sudo tee -a /etc/environment

# apt (apt-get)
apt_conf='/etc/apt/apt.conf'
if [ -f $apt_conf ]
then
	if [ -z "$username" ]
	then
		proxy_string='Acquire::http::Proxy "http://'$proxy'";'
	else
		if [ -z "$password" ]
		then
			proxy_string='Acquire::http::Proxy "http://'$esc_username'@'$proxy'";'
		else
			proxy_string='Acquire::http::Proxy "http://'$esc_username':'$password'@'$proxy'";'
		fi
	fi
	# echo $proxy_string
	echo "apt.conf exist, checking for proxy configuration"
	existing_proxy_lines=`grep "^Acquire::http::Proxy" $apt_conf`
	find_count=`echo $existing_proxy_lines | wc -l`
	if [ -z "$existing_proxy_lines" ]
	then
		echo sending proxy string $proxy_string to $apt_conf
		echo $proxy_string | sudo tee -a $apt_conf
	else
		echo "Existing proxy configuration"
		echo $existing_proxy_lines
		# sed_parameter="'s#$existing_proxy_lines#$proxy_string#'"
		exec_sed() {
			# echo sed -i "s#$1#$2#" $3
			sudo sed -i "s#$1#$2#" $3
		}
		echo "New proxy configuration"
		# echo $proxy_string
		exec_sed "$existing_proxy_lines" "$proxy_string" "$apt_conf"
	fi
else
	echo "apt.conf not exists, creating new file"
	echo $proxy_string | sudo tee $apt_conf
fi

# git
if [ -x "$(command -v git)" ]
then
	if [ -z "$username" ]
	then
		git_proxy_string='http://'$proxy
	else
		if [ -z "$password" ]
		then
			git_proxy_string='http://'$esc_username'@'$proxy
		else
			git_proxy_string='http://'$esc_username':'$password'@'$proxy
		fi
	fi
	git config --global http.proxy $git_proxy_string
fi

# npm
if [ -x "$(command -v npm)" ]
then
	if [ -z "$username" ]
	then
		npm_proxy_string='http://'$proxy
	else
		if [ -z "$password" ]
		then
			npm_proxy_string='http://'$esc_username'@'$proxy
		else
			npm_proxy_string='http://'$esc_username':'$password'@'$proxy
		fi
	fi
	npm_proxy_string='http://'$esc_username':'$password'@'$proxy
	npm config set http-proxy $npm_proxy_string
fi

