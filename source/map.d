import std.typecons : tuple, Tuple;
import std.array : popBack, empty;
import lib.exception : KeyError, ValueError;

import bitarray.bitarray;
import bitarray.builder;


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
        this.labels = t[1];  //labels of each node
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
      Return the node number of a child if exists.
     */
    private uint getChild(uint node_number, wchar character) {
        //get the index of the child node
        auto p = this.bitvector.select0(node_number-1) + 1;

        //search brothers
        for(auto i = p; this.bitvector[i] == 1; i++) {
            //index to node number
            auto child_node_number = this.bitvector.rank1(i);
            if(this.labels[child_node_number] == character) {
                return child_node_number;
            }
        }

        throw new ValueError("Child not found.");
    }

    /**
      Return the leaf node number if the query exists in the tree,
      throw KeyError otherwise.
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
                node_number = this.getChild(node_number, character);
            } catch(ValueError e) {
                throw new KeyError(word);
            }
        }
        return node_number;
    }

    /**
      Return the word associated with the node number.
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

        //reverse the word since searched from the leaf node
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
    testGetNodeNumber(["the", "then", "they"],
                      [4, 5, 6],
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

    testGetWord([5, 3, 6, 9, 10, 11],
                ["an", "i", "of", "one", "our", "out"]);
    testGetWord([4, 5, 6],
                ["the", "then", "they"]);
}
