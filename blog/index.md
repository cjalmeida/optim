@def title = "Articles"
@def pages = [string("posts/", p) for p in readdir("posts")]
# Articles

~~~
<ul>
{{for p in pages}}
  <li><a href="{{fill fd_url p}}">{{fill title p}}</a></li>
{{end}}
</ul>
~~~
