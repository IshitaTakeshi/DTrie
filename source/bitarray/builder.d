module bitarray.builder;

import std.typecons : tuple, Tuple;
import std.algorithm : reverse, sort, SwapStrategy;
import std.algorithm.iteration : map;
import std.conv : to;
import std.array : array;

import queue : Queue;
import bitarray.bitarray : SuccinctBitVector;


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


//TODO add a method to make on-line construction
/**
  This class has:<br>
  A function which constructs a tree by inserted words.<br>
  A function which dumps the tree as a LOUDS bit-string.<br>
 */
class LoudsBitStringBuilder {
    private Node tree;
    this(string[] words) {
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
        bitvector.append(1);
        bitvector.append(0);
        labels ~= cast(wchar)(' ');

        Queue!Node queue = new Queue!Node();
        queue.append(this.tree);

        while(!queue.isempty) {
            Node node = queue.pop();
            labels ~= node.label;

            // append N ones and 0
            // N is the number of children of the current node
            for(auto i = 0; i < node.getNChildren(); i++) {
                bitvector.append(1);
            }
            bitvector.append(0);

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


//Ensure the same bit string generated even if the word order is randomized.
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
