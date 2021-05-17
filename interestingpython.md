<link href="http://github.com/yrgoldteeth/darkdowncss/raw/master/darkdown.css" rel="stylesheet"></link> 

# Interesting Python features because I was bored

1\. Re-raising exception using `from`
```py
>>> try:
...     print(1 / 0)
... except Exception as exc:
...     raise RuntimeError("Something bad happened") from exc
...
Traceback (most recent call last):
  File "<stdin>", line 2, in <module>
ZeroDivisionError: int division or modulo by zero

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "<stdin>", line 4, in <module>
RuntimeError: Something bad happened
```

----

2\. Ellipsis
```py
>>> ...
Ellipsis
```
Ellipsis has 3 main uses in python.

1. Accessing and slicing multidimensional Arrays/Numpy indexing.

	- The ellipsis syntax may be used to indicate selecting in full any remaining unspecified dimensions.

		```py
		>>> n = numpy.arange(16).reshape(2, 2, 2, 2)
		>>> n
		array([[[[ 0,  1],
				 [ 2,  3]],

				[[ 4,  5],
				 [ 6,  7]]],


			   [[[ 8,  9],
				 [10, 11]],

				[[12, 13],
				 [14, 15]]]])
		>>> n[1, ..., 1]  # equivalent to n[1,:,:,1]
		array([[ 9, 11],
			   [13, 15]])
		>>> # also Ellipsis object can be used interchangeably
		>>> n[1, Ellipsis, 1]
		array([[ 9, 11],
			   [13, 15]])
		```

2. Type hinting
	- Ellipsis can be used in type hinting using the `typing` module when either the arguments of the function allows the type: `Any` or the return value of the function is of type: `Any`

	```py
	from typing import Callable

	# Argument type is assumed to be `Any`
	def foo(x: ...) -> None:
		pass

	# If you want dynamic attributes on your class, have it override "__setattr__"
	# or "__getattr__" in a stub or in your source code.
	#
	# "__setattr__" allows for dynamic assignment to names
	# "__getattr__" allows for dynamic access to names
	class A:
		# This will allow assignment to any A.x, if x is the same type as "value"
		# (use "value: Any" to allow arbitrary types)
		def __setattr__(self, name: str, value: int) -> None: ...

		# This will allow access to any A.x, if x is compatible with the return type
		def __getattr__(self, name: str) -> int: ...
	```

3. Using it as `pass`
	- Ellipsis can be used as `pass` in functions, like so:

	```py
	def foo():
		pass

	def bar():
		...

	# Both styles are the same
	```

----

3\. Underscore

Underscore is a pretty useful Python feature, and it allows us to ignore values. For example, if you only wanted 2 of the 3 return values of a function, you can use underscore. Here's an example of using underscore:
```py
a, _, b = (1, 2, 3) # a = 1, b = 3
```
You can also use underscore to ignore multiple values at once by combining it with asterisk, like this:
```py
a, *_, b = (7, 6, 5, 4, 3, 2, 1) # a = 7, b = 1
```
Underscore can be very useful in loops, especially if you don't care about what you're using to iterate over
```py
for _ in range(5):
	do_function() # will repeat 5 times
	print(_) # You can still access underscore's current value
```
If you're feeling especially evil, you can use underscore to separate part of numbers. For example:
```py
million = 1_000_000 # million = 1000000
binary = 0b_0010 # binary = 0b0010 = 2
octa = 0o_64 # octa = 0o64 = 52
hexa = 0x_23_ab # hex = 0x23ab = 9131
```
Underscore can also be used in private/internal function methods inside modules.
```py
# my_module.py
def func():
	return "wow this is cool"

def _private_func():
	return "wow this isnt cool"
```
```py
# ------
# In Python interpreter
>>> from my_module import *
>>> func()
'wow this is cool'
>>> _private_func()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
NameError: name '_private_func' is not defined
>>> # You can still access the function by accessing it directly
>>> import my_module
>>> my_module._private_func()
'wow this isnt cool'
```

----

4\. Python easter eggs

Python Has a few interesting easter eggs (more here: https://github.com/OrkoHunter/python-easter-eggs) but I'll show a few.
```py
>>> from __future__ import braces
  File "<stdin>", line 1
SyntaxError: not a chance
>>> from __future__ import barry_as_FLUFL
>>> 1 <> 2
True
>>> 1 != 2
  File "<stdin>", line 1
    1 != 2
      ^
SyntaxError: with Barry as BDFL, use '<>' instead of '!='
>>> import antigravity # see what happens
>>> import this # see what happens
```

----

5\. Decorators

Decorators in Python may seem extremely difficult, but they're not *too* bad. Decorators basically allow you to modify whatever function they're placed about, for example, adding a route to a Flask app by adding the `@app.route('/path')` decorator. Here's an example of a simple decorator that doesn't take any arguments to print the arguments of whatever function it's on
```py
>>> def print_args(function):
>>>     def wrapper(*args, **kwargs):
>>>         print('Arguments:', args, kwargs)
>>>         return function(*args, **kwargs)
>>>     return wrapper

>>> @print_args
>>> def write(text):
>>>     print(text)

>>> write('foo')
Arguments: ('foo',) {}
foo
```

----

6\. `else` in `for` and `while` loops.

You can use `else` in `for` and `while` loops apparently, which I didn't know about until making this. The `else` will execute once the loop is finished unless the `break` is called, which could be useful in some circumstances. Here's an example:
```py
for i in foo:
	if i == 0:
		break
else:
	print("i was never 0")

# This is the same code as the loop above, just without using else in the for loop
found = False
for i in foo:
	if i == 0:
		found = True
		break
if not found:
	print("i was never 0")
```

----

7\. In-place value swapping

This one is pretty self-explanatory, but really nice sometimes
```py
>>> a = 10
>>> b = 5
>>> a, b
(10, 5)

>>> a, b = b, a
>>> a, b
(5, 10)
```

----

8\. Readable regular expressions

In Python, you can expand and comment your regular expressions. Here's an example:

```py
>>> pattern = """
... ^                   # beginning of string
... M{0,4}              # thousands - 0 to 4 M's
... (CM|CD|D?C{0,3})    # hundreds - 900 (CM), 400 (CD), 0-300 (0 to 3 C's),
...                     #            or 500-800 (D, followed by 0 to 3 C's)
... (XC|XL|L?X{0,3})    # tens - 90 (XC), 40 (XL), 0-30 (0 to 3 X's),
...                     #        or 50-80 (L, followed by 0 to 3 X's)
... (IX|IV|V?I{0,3})    # ones - 9 (IX), 4 (IV), 0-3 (0 to 3 I's),
...                     #        or 5-8 (V, followed by 0 to 3 I's)
... $                   # end of string
... """
>>> re.search(pattern, 'M')
```

----

9\. Mutable default arguments problem

Be careful if you're using mutable default arguments, because they will only be initialized once instead of every time you call your function.
```py
>>> def foo(x=[]):
...     x.append(1)
...     print(x)
...
>>> foo()
[1]
>>> foo()
[1, 1]
>>> foo()
[1, 1, 1]
```
Instead of doing it this way, you should set the argument to something like `None` and replace the variable with the mutable if it is `None`. That sounds a little confusing, so here's an example:
```py
>>> def foo(x=None):
...     if x is None:
...         x = []
...     x.append(1)
...     print(x)
>>> foo()
[1]
>>> foo()
[1]
```
This feature would be something really annoying to debug if you didn't know about it, so it's a pretty useful thing to know.

----

10\. Argument unpacking

You can unpack variables into function arguments with the splat operator, which can be quite useful in some scenarios. Here's an example of what that means:
```py
def draw_point(x, y):
    # do whatever
	return None

point_foo = (3, 4)
point_bar = {'y': 3, 'x': 2}

# *point_foo is equivalent to feeding a function `3, 4`
# **point_bar is equivalent to feeding a function `y=3, x=2`

draw_point(*point_foo)
draw_point(**point_bar)
```
