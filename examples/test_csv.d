import std.csv : CSV, open;
import std.string : string;
import std.stdio : writeln;

void main(string[] args){
    writeln( "Path to csv file" );
    string filename = "spreadsheet.csv";
    writeln( "Parse the file and create a CSV object with , as separator");
    CSV myData1     = open( filename, "," );
    writeln( "Return what contain the line 2");
    writeln( myData1.getLine( 2 ) );
    writeln( "Return what contain lines 0 to 2");
    writeln( myData1.getSlicedLines( 0, 2 ) );
}
