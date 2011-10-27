import std.string;
import configFile;
import std.stdio    : writeln;

void main( string[] args ){
    writeln( "Path to conf file" );
    string filename = "config.conf";
    writeln( "Parse the file and create a ConfigFile object");
    ConfigFile conf = configFile.open( filename );
    writeln( "Print content and child from current section" );
    writeln( conf.toString );
    writeln( "Print content and child from sub section" );
    writeln( conf.get( "Library" ).get( "Dependencies" ).toString );
    writeln( "Print value of build key in Dependencies subsection" );
    writeln( conf.get( "Library" ).get( "Dependencies" )["build"] );
}
