DTrie
==========

The dictionary representation of the Trie data structure.

## Usage

```
import dtrie;

auto dictionary = new DTrie!(T)(keys, values);
assert(dictionary[keys[0]] == [values[0]]);
```

Where T is the type of an element of values.

## Examples

```
import dtrie;

auto dictionary = new DTrie!string(["Win", "hot"], ["Lose", "cold"]);
assert(dictionary["Win"] == ["Lose"]);
assert(dictionary["hot"] == ["cold"]);
dictionary["won"];  //KeyError
```

__Multi-byte strings are available.__

```
import dtrie;

string[] keys = [
    "あけます", "あけます",
    "あけました", "あけました",
];

string[] values = [
    "開けます", "明けます",
    "開けました", "明けました",
];

auto dictionary = new DTrie!(string)(keys, values);

//"あけます" is associated to "開けます" and "明けます"
assert(dictionary["あけます"] == ["開けます", "明けます"]);

//"あけました" is associated  to "開けました" and "明けました"
assert(dictionary["あけました"] == ["開けました", "明けました"]);
```


## Build options
* Running Tests

```
$dub test
```

* Generating documentations

```
$dub build --build=docs
```
