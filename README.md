DTrie
==========

The dictionary representation of the Trie data structure.


## Examples

```
auto dictionary = new Dictionary(["Win", "hot"], ["Lose", "cold"]);

assert(dictionary.get("Win") == ["Lose"]);
assert(dictionary.get("hot") == ["cold"]);
assert(dictionary.get("won") == []);
```

__Multi-byte strings are available.__

```
string[] keys = [
    "あけます", "あけます",
    "あけました", "あけました",
];

string[] values = [
    "開けます", "明けます",
    "開けました", "明けました",
];

auto dictionary = new Dictionary(keys, values);

//"あけます" is associated to "開けます" and "明けます" 
assert(dictionary.get("あけます") == ["開けます", "明けます"]);
//"あけました" is associated  to "開けました" and "明けました" 
assert(dictionary.get("あけました") == ["開けました", "明けました"]);
```


## Running Tests

```
$dmd test.d bitarray.d lib/exception.d lib/random/random.d lib/random/string.d queue.d dtrie.d -unittest 
$./test
```

Documentations can be generated by appending -D option to the compilation command.
