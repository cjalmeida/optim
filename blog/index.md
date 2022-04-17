@def title = "Articles"
@def pages = [string("posts/", p) for p in readdir("posts")]
# Articles

~~~
{{allposts}}
~~~
