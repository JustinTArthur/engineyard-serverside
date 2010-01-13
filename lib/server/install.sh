#!/bin/bash

real_script_path=$(which git-receive-pack)
real_script_dir=$(dirname $real_script_path)

real_script_new_dir="$real_script_dir/git-receive-pack_original"
real_script_new_path="$real_script_new_dir/git-receive-pack"

our_script_path="$(dirname $0)/git-receive-pack"

post_receive_hook_path="$(dirname $0)/post-receive"
post_receive_hook_new_path="$real_script_dir/engineyard_post-receive_hook"

if [[ ! -w "$real_script_path" ]]; then
	echo "You have to run this as root."
	exit 1
fi 


if [[ -f "$real_script_new_path" ]]; then
	cp $post_receive_hook_path $post_receive_hook_new_path
	chmod +x $post_receive_hook_new_path
	echo 'engineyard git hooks installed'
else
	mkdir -p $real_script_new_dir
	mv $real_script_path $real_script_new_path
	cp $our_script_path $real_script_path
	cp $post_receive_hook_path $post_receive_hook_new_path
	chmod +x $post_receive_hook_new_path
	echo 'engineyard git hooks installed'
fi
