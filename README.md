Louds-Trie
==========

Implementation of the Trie data structure.


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
    "あけます", "あけます", "あけます",
    "あけました", "あけました", "あけました"
];

string[] values = [
    "開けます", "明けます", "空けます",
    "開けました", "明けました", "空けました"
];

auto dictionary = new Dictionary(keys, values);

//"あけます" is associated to "開けます", "明けます" and "空けます".
assert(dictionary.get("あけます") == ["開けます", "明けます", "空けます"]);

//"あけました" is associated  to "開けました", "明けました" and "空けました"
assert(dictionary.get("あけました") ==
       ["開けました", "明けました", "空けました"]);
```


## Running Tests

```
$dmd test.d bitarray.d lib/exception.d lib/random/random.d lib/random/string.d queue.d trie.d -unittest 
$./test
```

Documentations can be generated by appending -D option to the compilation command.
