module configFile;

/*
This file is part of DParser.

    Foobar is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Foobar is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
*/

private import std.stream       : BufferedFile;
private import std.string       : format, stripLeft, stripRight;
private import std.array        : split;
private import std.stdio        : writeln, writefln, writef;
private import std.exception    : Exception;


/**
 * parse is a method for parse a INI file or config file.
 *
 * Returns: A Section object with all information
 *
 * Examples:
 * --------------------
 * import configFile;
 * string filePath  = "~/myGreatSetup.conf";
 * Section sections = configFile.open( filePath );
 * --------------------
 */

ConfigFile open( string filePath ){
    Section         root            = new Section("root", 0);           // root section
    Section         currentSection  = root;                             // reference to current section
    Section         nextSection     = null;
    BufferedFile    buffer          = new BufferedFile( filePath );
    foreach( char[] line; buffer ){                                     // read line by line
        try{
            line = line.stripLeft().stripRight();
            debug writefln( "line: %s", line );
            if( line == "" ){
                continue;
            }
            else if( line[0] == '[' ){                                  // section start
                nextSection = getSection( cast(string)line );           // get newest section
                debug writefln( "  current: %s-%s | next: %s-%s", currentSection.name, currentSection.level , nextSection.name, nextSection.level );
                if( currentSection.level < nextSection.level ){         // currentSection.level < nextSection.level
                    currentSection.addChild( nextSection );             // add a child to current section
                    currentSection = nextSection;                       // now current section go to next one
                }
                else if( currentSection.level == nextSection.level ){   // currentSection.level = nextSection.level
                    currentSection = currentSection.rewind( currentSection.parent.level );
                    debug writefln( "    current: %s-%s | next: %s-%s", currentSection.name, currentSection.level , nextSection.name, nextSection.level );
                    currentSection.addChild( nextSection );
                    currentSection = nextSection;
                }
                else{                                                   // currentSection.level > nextSection.level
                    currentSection = currentSection.rewind( nextSection.level - 1);
                    debug writefln( "    current: %s-%s | next: %s-%s", currentSection.name, currentSection.level , nextSection.name, nextSection.level );
                    currentSection.addChild( nextSection );
                    currentSection = nextSection;
                }
            }
            else{                                                       // read information corresponding to a section
                string[] words = split(cast(string)line, "=");          // get key / value peer
                foreach( ref string word; words )
                    word.stripRight().stripLeft();                      // remove space, before and after word
                debug writefln( "  words: %s", words );
                currentSection[ words[0] ] = words[1];
            }
        }
        catch(Exception e){
            writeln( "Error: config file seem to not not follow specification!" );
            writeln( e.msg );
            writefln( "Line: %s", line );
        }
    }
    root.shrink;
    return root;
}

alias Section ConfigFile;
class Section{
    private:
        string          _name;
        Section         _parent;
        Section[]       _childs;
        size_t          _level;
        size_t          _numberOfChild;
        string[string]  _dict;

    public:
        /**
         * Constructor for a Section object
         *
         * Params: name level
         */
        this(string name, size_t level){
            this._name           = name;
            this._level          = level;
            this._childs         = [];
            this._numberOfChild  = 0;
            this._dict           = null;
        }

        /**
         * Constructor for copy Section object
         *
         * Params: name parent level childs numberOfChild dict
         */
        this( string name, Section parent, size_t level, Section[] childs, size_t numberOfChild, string[string] dict ){
            this._name           = name;
            this._level          = level;
            this._childs.length  = childs.length;
            foreach(size_t index, child; childs)
                this._childs[index] = child.dup;
            this._numberOfChild  = numberOfChild;
            this._dict           = dict;
        }

        /**
         * addChild is used for add a subsection to current section
         *
         * Params: Section
         */
        void addChild( ref Section section ){
            if( _numberOfChild >= _childs.length )
                _childs.length      = _childs.length + 5;        // resize +5 for not resize 1 by 1
            section.parent          = this;
            _childs[_numberOfChild] = section;
            _numberOfChild++;
        }

        /**
         * Resize object to same size as data contained by the object
         */
        @property void shrink(){
            _childs.length = _numberOfChild;
            foreach( child; _childs )
                child.shrink;
        }

        /**
         * get return the subsection where name equal name given
         *
         * Params: name
         *
         * Retuns: Section
         */
        Section get( string name ){
            Section section     = null;
            bool    isSearching = true;
            size_t  index       = 0;
            while( isSearching ){
                if( index >= _numberOfChild )
                    isSearching = false;
                else if( _childs[index].name == name ){
                    isSearching = false;
                    section = _childs[index].dup;
                }
                index++;
            }
            return section;
        }


        string opIndex( string key ){
            return _dict[key];
        }

        void opIndexAssign( string  value, string key ){
            debug writefln("+ key: %s | value: %s", key, value);
            _dict[key.idup] = value.idup;
        }

        /**
         * rewind is used for come back to parent at level given
         *
         * Params: level
         */
        Section rewind( size_t levelToGo ){                            // rewind to parent level x
            Section section     = null;
            debug{
                if( _parent !is null ) writefln( "+ Rewind parent of %s-%s: %s-%s", _name, _level, _parent.name, _parent.level );
                else writefln( "+ Rewind no prent, current section: %s-%s", _name, _level,);
            }
            if( _level == levelToGo)
                section = this;
            else if( _level >= levelToGo)
                section = _parent.rewind( levelToGo );
            else
                throw new Exception("You try to go back when current section is lower where level you want to go!");
            return section;
        }

        /**
         * toString used for print current object state
         *
         * Returns: a string
         */
        @property override string toString(){
            string content = "";
            string start   = "";
            string end     = "";
            if( _name != "root" ){
                foreach(i; 0..level){
                    start   ~= "[";
                    end     ~= "]";
                }
                content ~= start ~ _name ~ end ~ "\n"; // [section1] ... [[section2]]
                foreach( key, value; _dict )
                    content ~= format( "%s=%s\n", key, value);
            }
            foreach(child; _childs){
                content ~= child.toString();
            }
            return content;
        }

        @property Section dup(){
            return new Section( this._name, this.parent, this._level, this._childs, this._numberOfChild, this._dict );
        }

        @property string name(){
            return _name.idup;
        }

        @property Section parent(){
            return _parent;
        }

        @property Section parent(Section section){
            return _parent = section;
        }

        @property Section[] childs(){
            return _childs.dup;
        }

        @property size_t level(){
            return _level;
        }

        @property size_t length(){
            return _numberOfChild;
        }

        @property string[] keys(){
            return _dict.keys;
        }

        @property string[] values(){
            return _dict.values;
        }

        @property void rehash(){
            _dict.rehash;
            foreach(child; _childs)
                child.rehash;
        }

}


/**
 * getSection create a Section line with corresponding line
 *
 * Returns: Section object
 *
 * Examples:
 * --------------------
 * string line      = "[default]";
 * Section section  = getSection( line );
 * --------------------
 */
Section getSection( string lineSection ){
    size_t  level           = 0;
    size_t  position        = 0;
    string  name            = "";
    // get level
    while( lineSection[level] == '[' ){
        level++;
    }
    position = level;
    // get section name
    while( lineSection[position] != ']' ){
        name ~= lineSection[position];
        position++;
    }
    debug writefln( "Read name: %s-%s", name, level );
    return new Section(name, level);
}
