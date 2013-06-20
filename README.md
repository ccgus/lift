# Layered Image File Type
That's the proposal for the name.

# Motivation behind this project
There is no standard and easy to parse image format that handles layers.  This project hopes to become just that by creating and documenting a container format using SQLite 3.

http://shapeof.com/archives/2013/4/we_need_a_standard_layered_image_format.html

# Why not use PSD or Whatever?
PSD is very complicated and hard to parse.  SQLite is everywhere and easy to use.  It's easy to get data in and out from just about any scripting language, and C bindings are no problem.

The goal is to make in unnecessary to parse bytes to get to layer data.

# Schema


