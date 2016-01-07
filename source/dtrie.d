module dtrie;

import map : WordNodeNumberMap;
import lib.exception : ValueError, KeyError;


struct IterableKeys {
    /*
       T is the type of a value.
     */

    private WordNodeNumberMap key_to_node_number;
    //node numbers each of which contains at least one value
    uint[] node_has_value;

    this(T)(WordNodeNumberMap key_to_node_number,
            T[][] node_number_value_map) {
        this.key_to_node_number = key_to_node_number;

        foreach(uint node_number, T[] values; node_number_value_map) {
            if(values.length > 0) {
                this.node_has_value ~= node_number;
            }
        }
    }

    int opApply(int delegate(string) dg) {
        int result;

        //if node_number_value_map[node_number] has value, traverse a tree from
        //a leaf to get the corresponding word
        foreach(uint node_number; this.node_has_value) {
            string word = this.key_to_node_number.getWord(node_number);

            result = dg(word);
            if(result != 0) {
                break;
            }
        }
        return result;
    }
}


interface Map(T) {
    //this(string[] keys, T[] values);
    T[] get(string key);
    IterableKeys byKey();
}


class WordWordMap : Map!string {
    /*
    This is a string-to-string dictionary implemented using
    a copule of trie trees.
    Trie provides a function which returns the node number given the key, and
    also has a function which returns the key given the node number.

    Algorithm:
        Construction:
            1. Build trie trees. One is with keys, and another one is with
            values.
            2. Associate node numbers given by each trie tree by array.
        Indexing access:
            1. Extract the node number associated with the key.
            2. Using a node number given by the key, obtain the corresponding
            node number of the trie tree build with values.
            3. Extract the value by the node number obtained at 2.
     */

    private WordNodeNumberMap key_to_node_number;
    private WordNodeNumberMap node_number_to_value;

    //Array to associate node numbers given from each key and node numbers
    //given from each value.
    //2D array is used to associate multiple values to one key.
    private uint[][] node_number_map;

    this(string[] keys, string[] values)
    body {
        this.key_to_node_number = new WordNodeNumberMap(keys);
        this.node_number_to_value = new WordNodeNumberMap(values);

        foreach(uint i, key; keys) {
            this.associateNodeNumbers(key, values[i]);
        }
    }

    /**
      Returns a forward range which will iterate over the keys of the dictionary.
     */
    @property IterableKeys byKey() {
        return IterableKeys(this.key_to_node_number,
                            this.node_number_map);
    }

    private void associateNodeNumbers(string key, string value) {
        uint k = this.key_to_node_number.getNodeNumber(key);
        uint v = this.node_number_to_value.getNodeNumber(value);

        //expand the associative array
        if(k >= this.node_number_map.length) {
            auto size = k+1-this.node_number_map.length;
            this.node_number_map ~= new uint[][](size, 0); //additional space
        }
        this.node_number_map[k] ~= v;
    }

    /**
      Return the values given the key.
      Empty array will be returned if the key doesn't exist in the
      key set.
     */
    string[] get(string key) {
        string[] values;
        uint k = this.key_to_node_number.getNodeNumber(key);
        uint[] node_numbers = this.node_number_map[k];

        if(node_numbers.length == 0) {
            throw new KeyError(key);
        }

        foreach(v; node_numbers) {
            values ~= this.node_number_to_value.getWord(v);
        }

        return values;
    }
}


///string to string
unittest {
    auto dictionary = new WordWordMap(["Win", "hot"], ["Lose", "cold"]);

    assert(dictionary.get("Win") == ["Lose"]);
    assert(dictionary.get("hot") == ["cold"]);

    bool error_thrown = false;
    try {
        dictionary.get("won");
    } catch(KeyError e) {
        error_thrown = true;
    }
    assert(error_thrown);
}


//smoke test
unittest {
    string[] keys = [
        "accept", "affirm", "include", "arrive", "invest",
        "begin", "offer", "conceal", "discharge", "recognize",
        "enrich", "rise", "expose", "remember", "sleep",
        "hide", "sink", "hurt", "wax", "accept",
        "affirm", "include", "arrive", "invest", "begin",
        "offer", "conceal", "discharge", "recognize", "enrich",
        "rise", "expose", "remember", "sleep", "hide",
        "sink", "hurt", "wax"
    ];

    string[] values = [
        "reject", "deny", "exclude", "depart", "divest",
        "end", "refuse", "reveal", "convict", "ignore",
        "impoverish", "fall, set", "conceal", "forget",
        "wake", "seek", "swim", "heal", "wane",
        "reject", "deny", "exclude", "depart", "divest",
        "end", "refuse", "reveal", "convict", "ignore",
        "impoverish", "fall, set", "conceal", "forget",
        "wake", "seek", "swim", "heal", "wane"
    ];

    auto dictionary = new WordWordMap(keys, values);
    foreach(ulong i, string key; keys) {
        assert(dictionary.get(key)[0] == values[i]);
    }
}


class WordObjectMap(T) : Map!T {
    /*
    string-to-object dictionary
    Algorithm:
        Construction:
            1. Build a trie tree with keys.
            2. Associate each node number to each corresponding value.
        Indexing access:
            1. Extract the node number associated with the key.
            2. Obtain the corresponding value by the node number.
     */

    private WordNodeNumberMap key_to_node_number;

    //Array to associate node numbers given from each key and node numbers
    //given from each value.
    //2D array is used to associate multiple values to one key.
    private T[][] node_number_value_map;

    this(string[] keys, T[] values)
    body {
        this.key_to_node_number = new WordNodeNumberMap(keys);

        foreach(ulong i, key; keys) {
            this.associateNodeNumberToValue(key, values[i]);
        }
    }

    @property IterableKeys byKey() {
        return IterableKeys(this.key_to_node_number,
                            this.node_number_value_map);
    }

    private void associateNodeNumberToValue(string key, T value) {
        uint k = this.key_to_node_number.getNodeNumber(key);

        //expand the associative array
        if(k >= this.node_number_value_map.length) {
            auto size = k+1-this.node_number_value_map.length;
            this.node_number_value_map ~= new T[][](size, 0); //additional space
        }
        this.node_number_value_map[k] ~= value;
    }

    /**
      Return the values given the key.
      Raise KeyError if key not found.
     */
    T[] get(string key) {
        uint k = this.key_to_node_number.getNodeNumber(key);
        return this.node_number_value_map[k];
    }
}


///string to int
unittest {
    auto dictionary = new WordObjectMap!(int)(["one", "two"], [1, 2]);
    assert(dictionary.get("one") == [1]);
    assert(dictionary.get("two") == [2]);


    bool error_thrown = false;
    try {
        dictionary.get("three");
    } catch(KeyError e) {
        error_thrown = true;
    }
    assert(error_thrown);
}


//TODO try to make only this class public
class DTrie(T) {
    private Map!(T) map;

    this(string[] keys, T[] values)
    in {
        if(keys.length != values.length) {
            throw new ValueError(
                "The number of keys doesn't match the number of values.");
        }
    }
    body {
        static if(is(T : string)) {
            //string specific map (less memory)
            this.map = new WordWordMap(keys, values);
        } else {
            //string-to-anytype map
            this.map = new WordObjectMap!(T)(keys, values);
        }
    }

    @property IterableKeys byKey() {
        return this.map.byKey;
    }
    unittest {
        import std.container;
        import std.range;
        import std.array;
        import std.algorithm;

        alias Set = make!(RedBlackTree!string);

        void testByKey(T)(string[] keys, T[] values) {
            auto map = new DTrie!T(keys, values);

            auto words = Set();
            foreach(word; map.byKey) {
                words.insert(word);
            }

            assert(equal(words[], keys));
        }

        //test for string-to-anytype map
        testByKey(["a", "an", "i", "of", "on", "one", "our", "out"],
                  [0, 1, 2, 3, 4, 5, 6, 7]);
        //test for string-to-string map
        testByKey(["a", "an", "i", "of", "on", "one", "our", "out"],
                  ["A", "AN", "I", "OF", "ON", "ONE", "OUR", "OUT"]);
    }

    T[] opIndex(string key) {
        return this.map.get(key);
    }
}


///
unittest {
    auto dictionary = new DTrie!string(["Win", "hot"], ["Lose", "cold"]);
    assert(dictionary["Win"] == ["Lose"]);
    assert(dictionary["hot"] == ["cold"]);


    bool error_thrown = false;
    try {
        dictionary["won"];
    } catch(KeyError e) {
        error_thrown = true;
    }
    assert(error_thrown);
}


///
unittest {
    auto dictionary = new DTrie!int(["one", "two"], [1, 2]);
    assert(dictionary["one"] == [1]);
    assert(dictionary["two"] == [2]);

    bool error_thrown = false;
    try {
        dictionary["three"];
    } catch(KeyError e) {
        error_thrown = true;
    }
    assert(error_thrown);
}


/// Multiple strings are available
//test for multibyte strings
unittest {
    string[] keys = [
        "すもーくちーず"
    ];

    string[] values = [
        "スモークチーズ"
    ];

    auto dictionary = new DTrie!(string)(keys, values);
    assert(dictionary["すもーくちーず"] == ["スモークチーズ"]);
}


unittest {
    auto america = new DTrie!string(
            ["Capital", "Currency"],
            ["Washington, D.C.", "Dollar"]);

    auto china = new DTrie!string(
            ["Capital", "Currency"],
            ["Beijing", "Renminbi"]);

    auto japan = new DTrie!string(
            ["Capital", "Currency"],
            ["Tokyo", "Yen"]);

    auto countries = new DTrie!(DTrie!string)(
            ["America", "China", "Japan"],
            [america, china, japan]);

    assert(countries["America"][0]["Capital"] == ["Washington, D.C."]);
    assert(countries["America"][0]["Currency"] == ["Dollar"]);

    assert(countries["China"][0]["Capital"] == ["Beijing"]);
    assert(countries["China"][0]["Currency"] == ["Renminbi"]);

    assert(countries["Japan"][0]["Capital"] == ["Tokyo"]);
    assert(countries["Japan"][0]["Currency"] == ["Yen"]);
}


//test for duplicate values
unittest {
    string[] keys = [
        "あけます", "あけます", "あけます",
        "あけました", "あけました", "あけました"
    ];

    string[] values = [
        "開けます", "明けます", "空けます",
        "開けました", "明けました", "空けました"
    ];

    auto dictionary = new DTrie!(string)(keys, values);
    assert(dictionary["あけます"] == ["開けます", "明けます", "空けます"]);
    assert(dictionary["あけました"] ==
            ["開けました", "明けました", "空けました"]);
}
