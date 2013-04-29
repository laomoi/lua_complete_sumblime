use strict;
use FindBin qw/$Bin/;
use Data::Dumper;

my @dirs = ('E:/quick-cocos2d-x/framework/client', 'E:/quick-cocos2d-x/framework/shared');
my $outupt = "E:/Sublime Text 2.0.1/Data/Packages/Lua/lua.sublime-completions";
my $luadir = $Bin . "lua5.1";
my $rh_parsed = {};

main();




sub main {
    parseLuaAPIDir();



    for my $d(@dirs){
        parseUserDirs($d, "");
    }

    #print Dumper($rh_parsed);


    #save
    my $triggers_content = "";
    for my $key(keys %$rh_parsed){
        my $functions = $rh_parsed->{$key}->{functions};
        my $fields = $rh_parsed->{$key}->{fields};

        for my $f(@$functions) {
            my $name = $f->{name};
            my $params = $f->{params};
            my $desc = $key . '.' . $name . '(' . join(",", @$params). ')';
            my @real_parms = map { "\$\{" . ($_ +1)."\}" . $params->[$_] } 0..(@$params-1);
            my $content = $key . '.' . $name . '(' . join(",", @real_parms). ')';
            my $trigger_tmpl = qq# { "trigger": "$desc", "contents": "$content" },#;
            $triggers_content .=  "\t\t" . $trigger_tmpl ."\n";
        }
 
         for my $field(@$fields) {
            my $desc = $key . '.' . $field ;
            my $content = $desc;
            my $trigger_tmpl = qq# { "trigger": "$desc", "contents": "$content" },#;
            $triggers_content .=  "\t\t" . $trigger_tmpl ."\n";
        }
 

    }


    my $file_tmpl = qq#
    {
        "scope": "source.lua - keyword.control.lua - constant.language.lua - string",

        "completions":
        [
            "in", "else", "return", "false", "true", "break", "or", "and",
$triggers_content    
            {}
        ]
    }#;

    open(F, '>', $outupt);
    print F $file_tmpl;
    close F;

}

sub parseLuaAPIDir {
    my @files = glob "$luadir/*.lua";


    for my $f(@files){
        open(F, '<', $f);
        my $c = join "", <F>;
        $c =~ s{\r\n}{\n}g;
        close F;

        $f =~ m{(\w+)$};
        my $short = $1;
        $rh_parsed->{$short} = {functions=>[], fields=>[]};

        #functions
        while ($c =~ m{\@function(.*?)\@return}gis) {
            my $snippet = $1;
            my @lines = split("\n");
            my $line1 = shift @lines;
            $line1 =~ m{\s(\w+)};
            my $func_name = $1;
            my $func_params = [];
            for my $l(@lines) {
                if ($l =~ m{^\@param.*?\s(\w+)}) {
                    push @$func_params, $1;
                }
            }

            push @{ $rh_parsed->{$short}->{functions}}, {name => $func_name, params => $func_params};

        }



        #fields
        while ($c =~ m{\@field.*?\s(\w+)}gis) {
            my $key = $1;
            push @{ $rh_parsed->{$short}->{fields}}, $key;
        }


        #UPPER CASE WORDS, they must be some CONSTANTS, 

        # while ($c =~ m{[A-Z_]}gis) {
        #     my $key = $1;
        #     push @{ $rh_parsed->{$short}->{fields}}, $key;
        # }

    }
}

sub parseUserDirs {
    my ($dir) = @_;

    my @files = glob "$dir/*";
    
    for my $f(@files){
        
        if (-d $f){
            $f =~ m{(\w+)$};
            my $short = $1;
            if (!$short){
                next;
            }
            parseUserDirs($f);
        } else {
            $f =~ m{(\w+)\.lua$};
            my $short = $1;
            if (!$short){
                next;
            }
            #parse file
            open(F, '<', $f);
            my $c = join "", <F>;
            close F;
            
            #fields
            my @fields = ();
            while ($c =~ m{\W*$short\.(\w+)\s*=}g) {
                push @fields, $1;
            }
             
       
            #functions
            my @functions = ();
            while ($c =~ m{function\s+$short(\.|\:)(\w+)\((.*?)\)}g) {
                my $name = $2;
                my $params = $3;
                $params =~ s{\s}{}g;
                my @params = split ",", $params;
                push @functions, {name=> $name, params=> \@params};
            }
            $rh_parsed->{$short} = {fields => \@fields, functions => \@functions};
            
          
        }
    }
}

__END__
    
{
    "scope": "source.lua - keyword.control.lua - constant.language.lua - string",

    "completions":
    [
        "in", "else", "return", "false", "true", "break", "or", "and",
        { "trigger": "ui.newNode(param)", "contents": "ui.a(${1})" },
        { "trigger": "ui.newAnimation(param)", "contents": "ui.b(${1})" },

        {}
    ]
}