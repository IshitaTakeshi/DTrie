module dtrie;
import std.typecons : tuple, Tuple;
import std.algorithm : reverse, sort, SwapStrategy;
import std.conv : to;

import queue : Queue;
import bitarray : SuccinctBitVector;
import lib.exception : ValueError, KeyError;

/**
The node of the tree.
Each node has one character as its member.
*/
class Node {
    wchar label;
    private Node[] children;
    bool visited;

    this(wchar label) {
        this.label = label;
        this.children = [];
        this.visited = false;
    }

    void addChild(Node child) {
        this.children ~= child;
    }

    ulong getNChildren() {
        return this.children.length;
    }
}


/**
This class has:<br>
    A function which constructs a tree by inserted words.<br>
    A function which dumps the tree as a LOUDS bit-string.<br>
*/
class LoudsBitStringBuilder {
    private Node tree;
    this(string[] words) {
        import std.conv : to;
        import std.algorithm.iteration : map;
        import std.array : array;

        this.tree = new Node(' ');  //make root

        //To avoid making effects to the outside of this class,
        //copy given string array into newly allocated string array
        string[] words_ = new string[words.length];
        words_[0..$] = words[0..$];

        //sort words in alphabetical order.
        sort!("a < b", SwapStrategy.stable)(words_);
        foreach(string word; words_) {
            wchar[] w = array(map!(to!wchar)(word));
            this.build(this.tree, w, 0);
        }
    }

    /**
    Build a tree.
    */
    private void build(Node node, wchar[] word, uint depth) {
        if(depth == word.length) {
            return;
        }

        foreach(Node child; node.children) {
            if(child.label == word[depth]) {
                this.build(child, word, depth+1);
                return;
            }
        }

        Node child = new Node(word[depth]);
        node.addChild(child);
        this.build(child, word, depth+1);
        return;
    }

    /**
    Dumps a LOUDS bit-string.
    */
    Tuple!(SuccinctBitVector, wchar[]) dump() {
        //construct a bit vector by Breadth-first search
        SuccinctBitVector bitvector = new SuccinctBitVector();
        wchar[] labels;

        //set the root node
        bitvector.push(1);
        bitvector.push(0);
        labels ~= cast(wchar)(' ');

        Queue!Node queue = new Queue!Node();
        queue.append(this.tree);

        while(!queue.isempty) {
            Node node = queue.pop();
            labels ~= node.label;

            // append N ones and 0
            // N is the number of children of the current node
            for(auto i = 0; i < node.getNChildren(); i++) {
                bitvector.push(1);
            }
            bitvector.push(0);

            foreach(Node child; node.children) {
                if(child.visited) {
                    continue;
                }

                child.visited = true;
                queue.append(child);
            }
        }

        bitvector.build();
        return tuple(bitvector, labels);
    }
}


//smoke test
unittest {
    string[] words = ["an", "i", "of", "one", "our", "out"];

    auto constructor = new LoudsBitStringBuilder(words);
    auto t = constructor.dump();
    SuccinctBitVector bitvector = t[0];

    //the length of the bitvector should be a multiple of 8
    assert(bitvector.toString() == "101110100111000101100000");
}


//Ensure the same bit string generated if the word order is randomized.
unittest {
    string[] words = ["our", "out", "i", "an", "of", "one"];

    auto constructor = new LoudsBitStringBuilder(words);
    auto t = constructor.dump();
    SuccinctBitVector bitvector = t[0];

    //the length of the bitvector should be a multiple of 8
    assert(bitvector.toString() == "101110100111000101100000");
}


unittest {
    string[] words = ["the", "then", "they"];

    auto constructor = new LoudsBitStringBuilder(words);
    auto t = constructor.dump();
    SuccinctBitVector bitvector = t[0];
    assert(bitvector.toString() == "1010101011000000");
}


/**
Map of words and node numbers with a trie.
*/
class WordNodeNumberMap {
    private SuccinctBitVector bitvector;
    private wchar[] labels;

    /**
    Build the dictionary.
    Raise ValueError if the empty string is contained in the words.
    */
    this(string[] words)
    in {
        foreach(string word; words) {
            if(word.length == 0) {
                throw new ValueError("Empty string recieved");
            }
        }
    }
    body {
        //convert words to a LOUDS bit-string
        auto t = new LoudsBitStringBuilder(words).dump();
        this.bitvector = t[0];  //LOUDS bit-string
        this.labels = t[1]; //labels of each node
    }
    //should raise ValueError if the empty string recieved
    unittest {
        bool error_thrown = false;
        try {
            WordNodeNumberMap map = new WordNodeNumberMap([""]);
        } catch(ValueError e) {
            error_thrown = true;
        }
        assert(error_thrown);
    }

    /**
    Return the node number of the child if exists.
    */
    private uint traceChildren(uint current_node_number, wchar character) {
        uint node_number;

        //get the corresponding index of the node number
        uint index = this.bitvector.select0(current_node_number-1);

        //numbers next to the index of the node mean the node's children
        //search brothers
        index += 1;
        while(this.bitvector.get(index) == 1) {
            node_number = this.bitvector.rank1(index);
            if(this.labels[node_number] == character) {
                return node_number;
            }
            index += 1;
        }

        throw new ValueError("Child not found.");
    }

    /**
    Return the leaf node number if the query exists in the tree and
    throws KeyError if not exist.
    */
    uint getNodeNumber(string word)
    in {
        if(word.length == 0) {
            throw new KeyError("Empty word.");
        }
    }
    body {
        uint node_number = 1;
        foreach(wchar character; word) {
            try {
                node_number = this.traceChildren(node_number, character);
            } catch(ValueError e) {
                throw new KeyError(word);
            }
        }
        return node_number;
    }

    /**
    Return the word the associated node number.
    */
    string getWord(uint node_number)
    in {
        if(node_number >= this.labels.length)  {
            throw new ValueError("Node number is too large.");
        }
    }
    body {
        wchar[] word;
        //search from the leaf node
        while(node_number != 1) {
            word ~= this.labels[node_number];

            //get the parent node
            uint index = this.bitvector.select1(node_number-1);
            node_number = this.bitvector.rank0(index);
        }

        //reverse the word because searched from the leaf node
        reverse(word);
        return word.to!string;
    }
}


//smoke test
unittest {
    void testGetNodeNumber(string[] keys, uint[] answers,
                           string[] words_not_in_keys) {
        WordNodeNumberMap map = new WordNodeNumberMap(keys);
        foreach(uint i, string key; keys) {
            //the set of keys in the dictionary should be found
            uint result = map.getNodeNumber(key);
            assert(result == answers[i]);
        }

        //KeyError should be thrown if the key is not found
        foreach(string word; words_not_in_keys) {
            bool error_thrown = false;
            try {
                map.getNodeNumber(word);
            } catch(KeyError e) {
                error_thrown = true;
            }
            if(!error_thrown) {
                import std.string : format;
                import core.exception : AssertError;
                throw new AssertError(
                        format("KeyError is not thrown at key '%s'", word));
            }
        }
    }

    testGetNodeNumber(["an", "i", "of", "one", "our", "out"],
                      [5, 3, 6, 9, 10, 11],
                      ["hello", "ant", "ones", "ours", ""]);
    testGetNodeNumber(["the", "then", "they"], [4, 5, 6],
                      ["hi", "thus", "that", "them", ""]);

    void testGetWord(uint[] node_numbers, string[] keys) {
        import std.algorithm : max, reduce;
        WordNodeNumberMap map = new WordNodeNumberMap(keys);
        sort!("a < b", SwapStrategy.stable)(keys);
        foreach(uint i, uint node_number; node_numbers) {
            string key = map.getWord(node_number);
            assert(key == keys[i]);
        }

        bool error_thrown = false;
        uint node_number = reduce!max(node_numbers) + 1;
        try {
            map.getWord(node_number);
        } catch(ValueError e) {
            error_thrown = true;
        }
        assert(error_thrown);
    }

    testGetWord([5, 3, 6, 9, 10, 11], ["an", "i", "of", "one", "our", "out"]);
    testGetWord([4, 5, 6], ["the", "then", "they"]);
}


//TODO try to make only this class public
//TODO consider the name
/**
Interface of kana-kanji dictionary.
*/
class Dictionary {
    /*
    This is the implementation of a string-to-string dictionary by
    using a copule of trie trees.
    Trie provides a function which returns the node number given the key, and
    also has a function which returns the key given the node number.
    Algorithm:
        Construction:
            1. Build trie trees. One is with keys, and another one is with
            values.
            2. Associate node numbers given by each trie tree using an
            associative array.
        Indexing access:
            1. Extract the node number associated with the key.
            2. Get the node number corresponding to the node number given by
            the key using the associative array.
            3. Extract the value with the node number obtained at 2.
    */

    private WordNodeNumberMap key_to_node_number;
    private WordNodeNumberMap node_number_to_value;
    //The initial size of the associative array is 0, but will be getting
    //expanded while building.
    private uint[][] node_number_map;

    this(string[] keys, string[] values)
    in {
        if(keys.length != values.length) {
            throw new ValueError(
                "The number of keys doesn't match the number of values.");
        }
    }
    body {
        this.key_to_node_number = new WordNodeNumberMap(keys);
        this.node_number_to_value = new WordNodeNumberMap(values);

        for(uint i = 0; i < keys.length; i++) {
            this.associate_node_numbers(keys[i], values[i]);
        }
    }

    private void associate_node_numbers(string key, string value) {
        uint key_node_number = this.key_to_node_number.getNodeNumber(key);
        uint value_node_number = this.node_number_to_value.getNodeNumber(value);
        //expand the associative array
        if(key_node_number >= this.node_number_map.length) {
            ulong size = key_node_number+1-this.node_number_map.length;
            this.node_number_map ~= new uint[][](size, 0); //additional space
        }
        this.node_number_map[key_node_number] ~= value_node_number;
    }

    /**
    Return the value given the key.
    Content of default_ will be returned if the key doesn't exist among the
    key set.
    */
    string[] get(string key) {
        string[] values;
        try {
            uint key_node_number = this.key_to_node_number.getNodeNumber(key);
            uint[] value_node_numbers = this.node_number_map[key_node_number];
            foreach(v; value_node_numbers) {
                values ~= this.node_number_to_value.getWord(v);
            }
        } catch(KeyError e) {
            return cast(string[])[];
        }
        return values;
    }
}


///
unittest {
    auto dictionary = new Dictionary(["Win", "hot"], ["Lose", "cold"]);
    assert(dictionary.get("Win") == ["Lose"]);
    assert(dictionary.get("hot") == ["cold"]);
    assert(dictionary.get("won") == []);
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

    auto dictionary = new Dictionary(keys, values);
    foreach(uint i, string key; keys) {
        assert(dictionary.get(key)[0] == values[i]);
    }
}


//test for multibyte strings
unittest {
    string[] keys = [
        "すもーくちーず"
    ];

    string[] values = [
        "スモークチーズ"
    ];

    auto dictionary = new Dictionary(keys, values);
    foreach(uint i, string key; keys) {
        assert(dictionary.get(key)[0] == values[i]);
    }
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

    auto dictionary = new Dictionary(keys, values);
    assert(dictionary.get("あけます") == ["開けます", "明けます", "空けます"]);
    assert(dictionary.get("あけました") ==
           ["開けました", "明けました", "空けました"]);
}