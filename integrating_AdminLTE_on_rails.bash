#!/bin/bash
#
# integrating_AdminLTE_on_rails.bash
#
# v0.0.1 - 2017-08-06 - Martin Cuellar <nelbren@gmail.com>
# v0.0.2 - 2017-09-23 - Martin Cuellar <nelbren@gmail.com>
# v0.0.3 - 2017-09-30 - Martin Cuellar <nelbren@gmail.com>
#
# Based on:
# https://hackernoon.com/using-bootstrap-in-rails-5-969cbe423926
# https://linuxconfig.org/how-to-install-ruby-on-rails-on-debian-9-stretch-linux
#

install_package() {
  package=$1
  if ! dpkg -s $package 2>/dev/null 1>&2; then
    sudo apt -y install $package
  fi
}

setup_packages() {
  install_package git 
  install_package ruby 
  install_package rails
}

make_project() {
  if [ ! -d $project ]; then
    rails new $project
  fi
}

get_adminlte() {
  if [ ! -d $base ]; then  
    git clone https://github.com/almasaeed2010/AdminLTE.git
  fi
}

install_main_css() {
  cp $base/dist/css/AdminLTE.css $project/app/assets/stylesheets/
}

install_main_js() {
  cp $base/dist/js/adminlte.js $project/app/assets/javascripts/
}

install_third_party_js() {
  if [ ! -d $project/vendor/assets/javascripts ]; then
    mkdir -p $project/vendor/assets/javascripts
  fi
  cp $base/bower_components/jquery-slimscroll/jquery.slimscroll.min.js $project/vendor/assets/javascripts/
}

install_skins() {
  if [ ! -d $project/app/assets/stylesheets/skins ]; then
    mkdir $project/app/assets/stylesheets/skins
  fi
  cp $base/dist/css/skins/* $project/app/assets/stylesheets/skins
}

replace() {
  cadena1=$1
  cadena2=$2
  archivo=$3
  if grep -q "$cadena1" $archivo; then
    sed "s/$cadena1/$cadena2/" $archivo > $filetemp
    mv $filetemp $archivo
  fi
}

append() {
  cadena=$1
  archivo=$2
  if ! grep -q "$cadena" $archivo; then
    echo $cadena >> $archivo
    gems_dirty=1
  fi
}

get_skin_random() {
  declare -a skins=('skin-black-light' 'skin-blue-light' 'skin-green-light' 'skin-purple-light' 'skin-red-light' 'skin-yellow-light' 'skin-black' 'skin-blue' 'skin-green' 'skin-purple' 'skin-red' 'skin-yellow');
  r=$(( ( RANDOM % 12 )  ))
  echo ${skins[$r]}
}

setup_style() {
  replace "*= require_tree ." "*= require style" $project/app/assets/stylesheets/application.css
  style=$project/app/assets/stylesheets/style.scss
  skin=$(get_skin_random)
  if [ ! -r $style ]; then
    cat << EOF > $style
  @import "bootstrap-sprockets";
  @import "bootstrap";
  @import "AdminLTE";
  @import "skins/$skin";
  @import "font-awesome";
EOF
  fi
}

setup_app() {
  app=$project/app/assets/javascripts/application.js 
  if ! grep -q "jquery.slimscroll.min" $app; then
    sed "s/\/\/= require_tree ./\/\/= require jquery\n\/\/= require bootstrap\n\/\/= require jquery.slimscroll.min\n\/\/= require_tree ./" $app > $filetemp
    mv $filetemp $app
  fi
}

change_directory() {
  cd $project
  dir=$(basename $(pwd))
  if [ "$dir" != "$project" ]; then
    echo "No pude cambiarme de directorio."
  fi
}

setup_gems() {
  gems=Gemfile
  gems_dirty=0
  append "gem 'bootstrap-sass', '~> 3.3.6'" $gems
  append "gem 'slim'" $gems
  append "gem 'font-awesome-rails', '~> 4.7', '>= 4.7.0.2'"
  append "gem 'jquery-rails', '~> 4.1', '>= 4.1.1'"
  if [ "$gems_dirty" == "1" ]; then
    bundle install
    sudo gem install slim
  fi
}

setup_controller() {
  controlador=app/controllers/greetings_controller.rb
  if [ ! -r $controlador ]; then
    rails generate controller Greetings hello
  fi
}

setup_view() {
  app=app/views/layouts/application.slim
  if [ ! -r $app ]; then
    cat << EOF > $app
doctype html
html
  head
    title Standup App
    = csrf_meta_tags
    = stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload'
    = javascript_include_tag 'application', 'data-turbolinks-track': 'reload'
body.fixed.$skin
    .wrapper
      = render 'layouts/navigation/layout'
      .content-wrapper
        = yield
      = render 'layouts/navigation/footer'
EOF
  fi
  app=app/views/layouts/application.html.erb
  if [ -r $app ]; then
    mv $app $app.bk
  fi
}

setup_layouts() {
  nav=app/views/layouts/navigation
  if [ ! -d $nav ]; then
    mkdir $nav
  fi
  layout=$nav/_layout.slim
  if [ ! -r $layout ]; then
    cat << EOF > $layout
= render "layouts/navigation/header"
= render "layouts/navigation/sidebar"
EOF
  fi
  layout=$nav/_header.slim
  if [ ! -r $layout ]; then
    cat << EOF > $layout
header.main-header
  a.logo href="/"
    | Standup App
  nav.navbar.navbar-static-top role="navigation"
    a.sidebar-toggle data-toggle="push-menu" role="button"
    .navbar-custom-menu
      ul.nav.navbar-nav
        li.dropdown.messages-menu
          a.dropdown-toggle data-toggle="dropdown" href="#"
            i.fa.fa-envelope-o
            span.label.label-success 4
          ul.dropdown-menu
            li.header You have 4 messages
            li
              ul.menu
                li
                  a href="#"
                  .pull-left
                    img.img-circle [ alt=("User Image")
                    src="http://placehold.it/160x160" ]
                  h4
                    | Sender Name
                    small
                      i.fa.fa-clock-o
                      | 5 mins
                  p Message Excerpt
                | \...
            li.footer
              a href="#"  See All Messages
        li.dropdown.notifications-menu
          a.dropdown-toggle data-toggle="dropdown" href="#"
            i.fa.fa-bell-o
            span.label.label-warning 10
          ul.dropdown-menu
            li.header You have 10 notifications
            li
              ul.menu
                li
                  a href="#"
                    i.ion.ion-ios-people.info
                    | Notification title
                | \...
            li.footer
              a href="#"  View all
        li.dropdown.tasks-menu
          a.dropdown-toggle data-toggle="dropdown" href="#"
            i.fa.fa-flag-o
            span.label.label-danger 9
          ul.dropdown-menu
            li.header You have 9 tasks
            li
              ul.menu
                li
                  a href="#"
                  h3
                    | Design some buttons
                    small.pull-right 20%
                  .progress.xs
                    .progress-bar.progress-bar-aqua [ aria-valuemax="100"
                    aria-valuemin="0" aria-valuenow="20" role="progressbar"
                    style=("width: 20%") ]
                      span.sr-only 20% Complete
                | \...
            li.footer
              a href="#"  View all tasks
        li.dropdown.user.user-menu
          a.dropdown-toggle data-toggle="dropdown" href="#"
            img.user-image alt=("User Image") src="http://placehold.it/160x160"
            span.hidden-xs Alexander Pierce
          ul.dropdown-menu
            li.user-header
              img.img-circle [ alt=("User Image")
              src="http://placehold.it/160x160" ]
              p
                | Alexander Pierce - Web Developer
                small Member since Nov. 2012
            li.user-body
              .col-xs-4.text-center
                a href="#"  Followers
              .col-xs-4.text-center
                a href="#"  Sales
              .col-xs-4.text-center
                a href="#"  Friends
            li.user-footer
              .pull-left
                a.btn.btn-default.btn-flat href="#"  Profile
              .pull-right
                a.btn.btn-default.btn-flat href="#"  Sign out
EOF
  fi
  layout=$nav/_sidebar.slim
  if [ ! -r $layout ]; then
    cat << EOF > $layout
.main-sidebar
  .sidebar
    .user-panel
      .pull-left.image
        img.img-circle alt=("User Image") src="http://placehold.it/160x160" /
      .pull-left.info
        p User Name
        a href="#"
          i.fa.fa-circle.text-success
          | Online
    form.sidebar-form action="#" method="get"
      .input-group
        input.form-control name="q" placeholder="Search..." type="text" /
        span.input-group-btn
          button#search-btn.btn.btn-flat name="search" type="submit"
            i.fa.fa-search
    ul.sidebar-menu
      li.header HEADER
      li.active
        a href="#"
          span Link
      li
        a href="#"
          span Another Link
      li.treeview
        a href="#"
          span Multilevel
          i.fa.fa-angle-left.pull-right
        ul.treeview-menu
          li
            a href="#"  Link in level 2
          li
            a href="#"  Link in level 2
EOF
  fi
  layout=$nav/_footer.slim
  if [ ! -r $layout ]; then
    cat << EOF > $layout
footer.main-footer
  .pull-right.hidden-xs
    | Anything you want
  strong
    | Copyright © 2016
    a href="#"  Company
  | All rights reserved.
EOF
  fi
}

stop_server() {
  ps -ef | grep "spring server" | grep -v grep | \
  while read line; do
    pid=$(echo $line | cut -d" " -f2)
    kill -9 $pid
  done
}

run_server() {
  echo -e "\nUse this url in your browser:\nhttp://localhost:3000/greetings/hello\n"
  rails s
}

myself=$(basename $0)

if [ -z $1 ]; then
  echo "Use: $myself rails-project"
  exit 1
fi

base=AdminLTE
project=$1
filetemp=$(mktemp /tmp/$myself.XXXXXXXX)

stop_server
setup_packages
make_project
get_adminlte
install_main_css
install_main_js
install_third_party_js
install_skins
setup_style
setup_app
change_directory
setup_gems
setup_controller
setup_view
setup_layouts
run_server
