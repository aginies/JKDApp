module JKDSeries {
    class Combo {
        var text as $.Toybox.Lang.String;
        var angles as $.Toybox.Lang.Array<$.Toybox.Lang.Number>;

        function initialize(t as $.Toybox.Lang.String, a as $.Toybox.Lang.Array<$.Toybox.Lang.Number>) {
            text = t;
            angles = a;
        }
    }

    class Series {
        var title as $.Toybox.Lang.String;
        var combos as $.Toybox.Lang.Array<Combo>;

        function initialize(t as $.Toybox.Lang.String, c as $.Toybox.Lang.Array<Combo>) {
            title = t;
            combos = c;
        }
    }

    function getSeries() as $.Toybox.Lang.Array<Series> {
        return [
            new Series("3 counts", [
                new Combo("Jab L + Cross R + Jik Tek L", []),
                new Combo("Jab L + Cross R + Hou Jik Tek R", []),
                new Combo("Jab L + Cross R + Nan Tek L", []),
                new Combo("Jab L + Cross R + Hou Nan Tek R", []),
                new Combo("Jab L + Cross R + Lateral step L + Juk Tek L", []),
                new Combo("Jab L + Cross R + Lateral step R + Juk Tek R", []),
                new Combo("Jab L + Cross R + Lateral step R + Sut Da R", []),
                new Combo("Jab L + Cross R + Lateral step L + Hou Sut Da L", []),
                new Combo("Jab L + Cross R + Jang L", []),
                new Combo("Jab L + Cross R + Jang R", []),
                new Combo("Jab L + Cross R + Hook R", []),
                new Combo("Jab L + Cross R + Yun Jeong R", [])
            ]),
            new Series("4 counts", [
                new Combo("Nan Tek L + Cross R + Hook L + Hou Nan Tek R", []),
                new Combo("Hou Nan Tek R + Hook L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Hook L + Nan Tek L", []),
                new Combo("Hou Nan Tek L + Cross R + Hook L + Hou Nan Tek R", []),
                new Combo("Jab L + Cross R + Nan Tek L + Hou Nan Tek R", []),
                new Combo("Jab L + Cross R + Hou Nan Tek L + Nan Tek R", []),
                new Combo("Jab L + Cross R + Nan Tek L + Nan Tek L", []),
                new Combo("Jab L + Cross R + Hou Nan Tek R + Hou Nan Tek R", []),
                new Combo("Jab L + Cross R + Hook L + Hou Nan Tek R", []),
                new Combo("Cross R + Hook L + Cross R + Nan Tek L", []),
                new Combo("Jab L + Hou Nan Tek R + Cross L + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Hou Nan Tek L + Change guard + Cross R", []),
                new Combo("Nan Tek L + Cross R + Hou Nan Tek R + Lateral step R + Hook L", []),
                new Combo("Nan Tek L + Cross R + Hou Nan Tek R + Toy Ma + Jab L", [])
            ]),
            new Series("5 counts", [
                new Combo("Nan Tek L + Cross R + Hook L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Uppercut L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Overhead R + Uppercut L + Overhead R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Jab L + Cross R + Nan Tek L", []),
                new Combo("Jab L + Cross R + Nan Tek L + Cross R + Hook L", []),
                new Combo("Jab L + Cross R + Body Hook L + Cross R + Nan Tek L", []),
                new Combo("Jab L + Cross R + Uppercut L + Cross R + Nan Tek L", []),
                new Combo("Jab L + Overhead R + Overhead L + Uppercut R + Nan Tek L", []),
                new Combo("Jab L + Cross R + Jab L + Cross R + Nan Tek L", [])
            ]),
            new Series("6 counts", [
                new Combo("Nan Tek L + Cross R + Da L + Jang R + Sut Da R + Hou Nan Tek R", []),
                new Combo("Nan Tek L + Cross R + Jang L + Jang R + Sut Da R + Hou Nan Tek R", []),
                new Combo("Nan Tek L + Cross R + Jang R + Sut Da R + Hou Nan Tek R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Jang R + Sut Da R + Nan Tek L + Hou Nan Tek R", [])
            ]),
            new Series("7 déplacements Kali", [
                new Combo("Step In Step Back L + Step In Step Back R", []),
                new Combo("Retirada Illustrissimo + Step Forward Front Leg -> Slide Back Foot + Step Backward Back Leg -> Slide Front Foot", []),
                new Combo("Retirada Cabaleiro + Step Forward Back Leg -> Slide Back Foot + Step Backward Front Leg -> Slide Front Foot", []),
                new Combo("Tadsoulok + Tadsoulok + Silat + Tadsoulok + Escrima", []),
                new Combo("Iliag UPO + Position Squat", []),
                new Combo("Iliag Iliag + Tadsoulok -> Bob and Wave", []),
                new Combo("Ag Bong Power + Step Forward Front Leg -> Rotation 1/4 -> Step Backward Back Leg -> Slide Front Foot", [])
            ]),
            new Series("ABC", [
                new Combo("Nan Tek L + Cross R + Hook L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Uppercut L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Overhead R + Uppercut L + Overhead R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Jab L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Nan Tek R", []),
                new Combo("Nan Tek L + Cross R + Uppercut L + Uppercut R + Hook L + Cross R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Hook R + Cross L + Nan Tek R", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Jang R + Jang L + Hou Sut Da R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Hook R + Cross L + Jang R + Jang L + Hou Sut Da R + Nan Tek L", []),
                new Combo("Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Hook R + Cross L + Jang R + Jang L + Hou Sut Da R + Sut Da L + Hou Nan Tek R + Nan Tek L", [])
            ]),
            new Series("Contre Jab Cross", [
                new Combo("Jab L -> Pak Sao R + Cross R -> Shoulder Roll L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> Pari Nan Tek L", []),
                new Combo("Jab L -> Pak Sao R + Cross (Open) R -> Inside Wedge L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> Low line Hit L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> High line Hit Internal L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> High line Hit External R", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> Biu Jee L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> Biu Jee + Huen Sao L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> Woang Pack Sao, Biu Jee, Nan Tek L", []),
                new Combo("Jab L -> Pak Sao R + Cross R -> Woang Pack Sao, Biu Jee L", []),
                new Combo("Jab L -> Pak Sao R + Cross (Open) R -> Shoulder Stop L", []),
                new Combo("Jab L -> Pak Sao R + Cross (Open) R -> Insinida L", []),
                new Combo("Jab L -> Pak Sao R + Cross (Open) R -> Bob and Wave L", [])
            ]),
            new Series("Contre Jab Hook", [
                new Combo("Jab L -> Pak Sao R + Hook R -> Shoulder Roll L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Inside Wedge L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Insinida L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Bob and Wave L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Shoulder stop, knee, guard change L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> White cover forward L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Panatukan forward L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Silat L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Shoulder stop, knee, pull arm L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Hou Juk Tek R", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Jeet Tek L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Nan Tek L", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Hou Dum Tek R", []),
                new Combo("Jab L -> Pak Sao R + Hook R -> Hou So Tek R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Shoulder Stop R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Biceps Stop R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> John Wayne R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Inside Wedge R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Insinida R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Bob and Wave R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Hou Juk Tek R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Jeet Tek L", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Hou Dum Tek R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Hou So Tek R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Woang Pack Sao, Biu Jee R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Woang Pack Sao, Biu Sao, Biu Jee R", []),
                new Combo("Jab L -> Pak Sao R + Hook L -> Woang Pack Sao, Biu Jee, Pak Sao, Biu Jee R", [])
            ]),
            new Series("Step and Slide", [
                new Combo("1: Move forward L", []),
                new Combo("2: Move backward L", []),
                new Combo("3: Move front leg side L", []),
                new Combo("4: Move rear leg side L", []),
                new Combo("5: Rotation CCW L", []),
                new Combo("6: Rotation CW L", []),
                new Combo("1: Move forward R", []),
                new Combo("2: Move backward R", []),
                new Combo("3: Move front leg side R", []),
                new Combo("4: Move rear leg side R", []),
                new Combo("6: Rotation CCW R", []),
                new Combo("5: Rotation CW R", [])
            ]),
            new Series("Slide and Step", [
                new Combo("1: Move forward L", []),
                new Combo("2: Move backward L", []),
                new Combo("3: Move front leg side L", []),
                new Combo("4: Move rear leg side L", []),
                new Combo("5: Rotation CCW L", []),
                new Combo("6: Rotation CW L", []),
                new Combo("1: Move forward R", []),
                new Combo("2: Move backward R", []),
                new Combo("3: Move front leg side R", []),
                new Combo("4: Move rear leg side R", []),
                new Combo("6: Rotation CCW R", []),
                new Combo("5: Rotation CW R", [])
            ]),
            new Series("Push Shuffle", [
                new Combo("1: Move forward L", []),
                new Combo("2: Move backward L", []),
                new Combo("3: Move front leg side L", []),
                new Combo("4: Move rear leg side L", []),
                new Combo("5: Rotation CCW L", []),
                new Combo("6: Rotation CW L", []),
                new Combo("1: Move forward R", []),
                new Combo("2: Move backward R", []),
                new Combo("3: Move front leg side R", []),
                new Combo("4: Move rear leg side R", []),
                new Combo("6: Rotation CCW R", []),
                new Combo("5: Rotation CW R", [])
            ]),
            new Series("Rock Shuffle", [
                new Combo("1: Move forward L", []),
                new Combo("2: Move backward L", []),
                new Combo("3: Move front leg side L", []),
                new Combo("4: Move rear leg side L", []),
                new Combo("5: Rotation CCW L", []),
                new Combo("6: Rotation CW L", []),
                new Combo("1: Move forward R", []),
                new Combo("2: Move backward R", []),
                new Combo("3: Move front leg side R", []),
                new Combo("4: Move rear leg side R", []),
                new Combo("6: Rotation CCW R", []),
                new Combo("5: Rotation CW R", [])
            ]),
            new Series("Pendulum", [
                new Combo("1: Move forward L", []),
                new Combo("2: Move backward L", []),
                new Combo("3: Move front leg side L", []),
                new Combo("4: Move rear leg side L", []),
                new Combo("5: Rotation CCW L", []),
                new Combo("6: Rotation CW L", []),
                new Combo("1: Move forward R", []),
                new Combo("2: Move backward R", []),
                new Combo("3: Move front leg side R", []),
                new Combo("4: Move rear leg side R", []),
                new Combo("6: Rotation CCW R", []),
                new Combo("5: Rotation CW R", [])
            ]),
            new Series("Hou ou tek", [
                new Combo("Hou Nan Tek R -> Jeet Tek L -> Nan Tek L", []),
                new Combo("Hou Nan Tek R -> Juk Tek L -> Nan Tek L", []),
                new Combo("Hou Nan Tek R -> Gwa Tek L -> Nan Tek L", []),
                new Combo("Hou Nan Tek R -> Jun Juk Tek R -> Nan Tek L", []),
                new Combo("Hou Nan Tek R -> Jun Gwa Tek R -> Nan Tek L", []),
                new Combo("Hou Nan Tek R -> Jun So Tek R -> Nan Tek L", [])
            ]),
            new Series("Innosanto Angles", [
                new Combo("Angle 1", [1]),
                new Combo("Angle 2", [2]),
                new Combo("Angle 3", [3]),
                new Combo("Angle 4", [4]),
                new Combo("Angle 5", [5]),
                new Combo("Angle 6", [6]),
                new Combo("Angle 7", [7]),
                new Combo("Angle 8", [8]),
                new Combo("Angle 9", [9]),
                new Combo("Angle 10", [10]),
                new Combo("Angle 11", [11]),
                new Combo("Angle 12", [12]),
                new Combo("Angle 13", [13]),
                new Combo("Angle 14", [14]),
                new Combo("Angle 15", [15]),
                new Combo("Pic remontant vers la Gauche", [])
            ]),
            new Series("18 Kicks", [
                new Combo("Jeet Tek L", []),
                new Combo("Hou Jeet Tek R", []),
                new Combo("Jik Tek L", []),
                new Combo("Hou Jik Tek R", []),
                new Combo("Nan Tek L", []),
                new Combo("Hou Nan Tek R", []),
                new Combo("Juk Tek L", []),
                new Combo("Hou Juk Tek R", []),
                new Combo("Gwa Tek L", []),
                new Combo("Hou Gwa Tek R", []),
                new Combo("So Tek L", []),
                new Combo("Hou So Tek R", []),
                new Combo("Jun Juk Tek R", []),
                new Combo("Hou Jun Juk Tek L", []),
                new Combo("Jun Gwa Tek R", []),
                new Combo("Hou Jun Gwa Tek L", []),
                new Combo("Jun So Tek R", []),
                new Combo("Hou Jun So Tek L", [])
            ]),
            new Series("Loyda JFK", [
                new Combo("Jab L", [])
            ]),
            new Series("Ping Chui Laop Sao Gwa Chui series", [
                new Combo("Low line Hit L -> Vertical Locking L -> Pak Sao R -> Jab L -> Through Locking R -> Bong Sao L -> Lop Sao R -> Gwa Chuie L", []),
                new Combo("Low line Hit L -> Vertical Locking L -> Pak Sao R -> Jab L -> Through Locking R -> Bong Sao L -> Lop Sao R -> Gwa Chuie L", []),
                new Combo("Low line Hit L -> Vertical Locking L -> Pak Sao R -> Jab L -> Vertical Locking R -> Pak Sao R -> Jab L -> Through Locking -> Bong Sao L -> Lop Sao R -> Gwa Chuie L", []),
                new Combo("Low line Hit L -> Vertical Locking L -> Pak Sao R -> Jab L -> Vertical Locking L -> Pak Sao R -> Jab L -> Through Locking R -> Bong Sao L -> Lop Sao R -> Da L", []),
                new Combo("Low line Hit L -> Vertical Locking L -> Pak Sao R -> Jab L -> Vertical Locking R -> Pak Sao R -> Jab L -> Through Locking R -> Bong Sao L -> Pak Sao L -> Lop Sao R -> Da L", [])
            ]),
            new Series("22 Coups de poings", [
                new Combo("Jab L", []),
                new Combo("Cross R", []),
                new Combo("Body Hook R", []),
                new Combo("Body Hook L", []),
                new Combo("Uppercut R", []),
                new Combo("Uppercut L", []),
                new Combo("Hook R", []),
                new Combo("Hook L", []),
                new Combo("Body Jab L", []),
                new Combo("Body Cross R", []),
                new Combo("Swing R", []),
                new Combo("Swing L", []),
                new Combo("OverHead R", []),
                new Combo("Uppercut L", []),
                new Combo("OverHead L", []),
                new Combo("Uppercut R", []),
                new Combo("Qua Chuie / cross R", []),
                new Combo("Qua Chuie / Jab L", []),
                new Combo("Frappes Marteau R", []),
                new Combo("Frappes Marteau L", []),
                new Combo("overhead poing avant R", []),
                new Combo("overhead poing arrière L", [])
            ]),
            new Series("Sinawali series", [
                new Combo("Cob Cob -> Pay Pay -> Ikis -> H L H -> Dos Ikis -> H L (Through) -> Even Six Heaven -> Even Six Standard -> Even Six Earth -> Umbrella Heaven -> Umbrella Standard -> Umbrella Earth -> Backend Six Heaven -> Backend Six Standard -> Backend Six Earth -> Upword Six count -> Ordabis Motion -> Sang Kite", [])
            ]),
            new Series("Trapping 9 entrées de base", [
                new Combo("Pak Sao R -> Jab L", []),
                new Combo("Pak Sao R -> Jab L -> Vertical Locking L -> Pak Sao R -> Jab L", []),
                new Combo("Pak Sao R -> Jab L -> Catch Arm L -> Jab R -> Pak Sao R -> Jab L", []),
                new Combo("Pak Sao R -> Jab L -> Vertical Locking L -> Tan Sao L -> Pak Sao R -> Jab L", [])
            ])
        ];
    }
}
