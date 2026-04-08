module JKDSeries {
    class Series {
        var title as $.Toybox.Lang.String;
        var combos as $.Toybox.Lang.Array<$.Toybox.Lang.String>;

        function initialize(t as $.Toybox.Lang.String, c as $.Toybox.Lang.Array<$.Toybox.Lang.String>) {
            title = t;
            combos = c;
        }
    }

    function getSeries() as $.Toybox.Lang.Array<Series> {
        return [
            new Series("3 counts", [
                "Jab L + Cross R + Jik Tek L",
                "Jab L + Cross R + Hou Jik Tek R",
                "Jab L + Cross R + Nan Tek L",
                "Jab L + Cross R + Hou Nan Tek R",
                "Jab L + Cross R + Lateral step L + Juk Tek L",
                "Jab L + Cross R + Lateral step R + Juk Tek R",
                "Jab L + Cross R + Lateral step R + Sut Da R",
                "Jab L + Cross R + Lateral step L + Hou Sut Da L",
                "Jab L + Cross R + Jang L",
                "Jab L + Cross R + Jang R",
                "Jab L + Cross R + Hook R",
                "Jab L + Cross R + Yun Jeong R"
            ]),
            new Series("4 counts", [
                "Nan Tek L + Cross R + Hook L + Hou Nan Tek R",
                "Hou Nan Tek R + Hook L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Hook L + Nan Tek L",
                "Hou Nan Tek L + Cross R + Hook L + Hou Nan Tek R",
                "Jab L + Cross R + Nan Tek L + Hou Nan Tek R",
                "Jab L + Cross R + Hou Nan Tek L + Nan Tek R",
                "Jab L + Cross R + Nan Tek L + Nan Tek L",
                "Jab L + Cross R + Hou Nan Tek R + Hou Nan Tek R",
                "Jab L + Cross R + Hook L + Hou Nan Tek R",
                "Cross R + Hook L + Cross R + Nan Tek L",
                "Jab L + Hou Nan Tek R + Cross L + Nan Tek L",
                "Nan Tek L + Cross R + Hou Nan Tek L + Change guard + Cross R",
                "Nan Tek L + Cross R + Hou Nan Tek R + Lateral step R + Hook L",
                "Nan Tek L + Cross R + Hou Nan Tek R + Toy Ma + Jab L"
            ]),
            new Series("5 counts", [
                "Nan Tek L + Cross R + Hook L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Body Hook L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Uppercut L + Cross R + Nan Tek L",
                "Nan Tek L + Overhead R + Uppercut L + Overhead R + Nan Tek L",
                "Nan Tek L + Cross R + Jab L + Cross R + Nan Tek L",
                "Jab L + Cross R + Nan Tek L + Cross R + Hook L",
                "Jab L + Cross R + Body Hook L + Cross R + Nan Tek L",
                "Jab L + Cross R + Uppercut L + Cross R + Nan Tek L",
                "Jab L + Overhead R + Overhead L + Uppercut R + Nan Tek L",
                "Jab L + Cross R + Jab L + Cross R + Nan Tek L"
            ]),
            new Series("6 counts", [
                "Nan Tek L + Cross R + Da L + Jang R + Sut Da R + Hou Nan Tek R",
                "Nan Tek L + Cross R + Jang L + Jang R + Sut Da R + Hou Nan Tek R",
                "Nan Tek L + Cross R + Jang R + Sut Da R + Hou Nan Tek R + Nan Tek L",
                "Nan Tek L + Cross R + Jang R + Sut Da R + Nan Tek L + Hou Nan Tek R"
            ]),
            new Series("7 déplacements Kali", [
                "Step In Step Back L + Step In Step Back R",
                "Retirada Illustrissimo + Step Forward Front Leg -> Slide Back Foot + Step Backward Back Leg -> Slide Front Foot",
                "Retirada Cabaleiro + Step Forward Back Leg -> Slide Back Foot + Step Backward Front Leg -> Slide Front Foot",
                "Tadsoulok + Tadsoulok + Silat + Tadsoulok + Escrima",
                "Iliag UPO + Position Squat",
                "Iliag Iliag + Tadsoulok -> Bob and Wave",
                "Ag Bong Power + Step Forward Front Leg -> Rotation 1/4 -> Step Backward Back Leg -> Slide Front Foot"
            ]),
            new Series("ABC", [
                "Nan Tek L + Cross R + Hook L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Body Hook L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Uppercut L + Cross R + Nan Tek L",
                "Nan Tek L + Overhead R + Uppercut L + Overhead R + Nan Tek L",
                "Nan Tek L + Cross R + Jab L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Nan Tek R",
                "Nan Tek L + Cross R + Uppercut L + Uppercut R + Hook L + Cross R + Nan Tek L",
                "Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Hook R + Cross L + Nan Tek R",
                "Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Jang R + Jang L + Hou Sut Da R + Nan Tek L",
                "Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Hook R + Cross L + Jang R + Jang L + Hou Sut Da R + Nan Tek L",
                "Nan Tek L + Cross R + Body Hook L + Hook R + Cross L + Uppercut R + Uppercut L + Hook R + Cross L + Jang R + Jang L + Hou Sut Da R + Sut Da L + Hou Nan Tek R + Nan Tek L"
            ]),
            new Series("Contre Jab Cross", [
                "Jab L -> Pak Sao R + Cross R -> Shoulder Roll L",
                "Jab L -> Pak Sao R + Cross R -> Pari Nan Tek L",
                "Jab L -> Pak Sao R + Cross (Open) R -> Inside Wedge L",
                "Jab L -> Pak Sao R + Cross R -> Low line Hit L",
                "Jab L -> Pak Sao R + Cross R -> High line Hit Internal L",
                "Jab L -> Pak Sao R + Cross R -> High line Hit External R",
                "Jab L -> Pak Sao R + Cross R -> Biu Jee L",
                "Jab L -> Pak Sao R + Cross R -> Biu Jee + Huen Sao L",
                "Jab L -> Pak Sao R + Cross R -> Woang Pack Sao, Biu Jee, Nan Tek L",
                "Jab L -> Pak Sao R + Cross R -> Woang Pack Sao, Biu Jee L",
                "Jab L -> Pak Sao R + Cross (Open) R -> Shoulder Stop L",
                "Jab L -> Pak Sao R + Cross (Open) R -> Insinida L",
                "Jab L -> Pak Sao R + Cross (Open) R -> Bob and Wave L"
            ]),
            new Series("Contre Jab Hook", [
                "Jab L -> Pak Sao R + Hook R -> Shoulder Roll L",
                "Jab L -> Pak Sao R + Hook R -> Inside Wedge L",
                "Jab L -> Pak Sao R + Hook R -> Insinida L",
                "Jab L -> Pak Sao R + Hook R -> Bob and Wave L",
                "Jab L -> Pak Sao R + Hook R -> Shoulder stop, knee, guard change L",
                "Jab L -> Pak Sao R + Hook R -> White cover forward L",
                "Jab L -> Pak Sao R + Hook R -> Panatukan forward L",
                "Jab L -> Pak Sao R + Hook R -> Silat L",
                "Jab L -> Pak Sao R + Hook R -> Shoulder stop, knee, pull arm L",
                "Jab L -> Pak Sao R + Hook R -> Hou Juk Tek R",
                "Jab L -> Pak Sao R + Hook R -> Jeet Tek L",
                "Jab L -> Pak Sao R + Hook R -> Nan Tek L",
                "Jab L -> Pak Sao R + Hook R -> Hou Dum Tek R",
                "Jab L -> Pak Sao R + Hook R -> Hou So Tek R",
                "Jab L -> Pak Sao R + Hook L -> Shoulder Stop R",
                "Jab L -> Pak Sao R + Hook L -> Biceps Stop R",
                "Jab L -> Pak Sao R + Hook L -> John Wayne R",
                "Jab L -> Pak Sao R + Hook L -> Inside Wedge R",
                "Jab L -> Pak Sao R + Hook L -> Insinida R",
                "Jab L -> Pak Sao R + Hook L -> Bob and Wave R",
                "Jab L -> Pak Sao R + Hook L -> Hou Juk Tek R",
                "Jab L -> Pak Sao R + Hook L -> Jeet Tek L",
                "Jab L -> Pak Sao R + Hook L -> Hou Dum Tek R",
                "Jab L -> Pak Sao R + Hook L -> Hou So Tek R",
                "Jab L -> Pak Sao R + Hook L -> Woang Pack Sao, Biu Jee R",
                "Jab L -> Pak Sao R + Hook L -> Woang Pack Sao, Biu Sao, Biu Jee R",
                "Jab L -> Pak Sao R + Hook L -> Woang Pack Sao, Biu Jee, Pak Sao, Biu Jee R"
            ]),
            new Series("Step and Slide", [
                "1: Move forward L",
                "2: Move backward L",
                "3: Move front leg side L",
                "4: Move rear leg side L",
                "5: Rotation CCW L",
                "6: Rotation CW L",
                "1: Move forward R",
                "2: Move backward R",
                "3: Move front leg side R",
                "4: Move rear leg side R",
                "6: Rotation CCW R",
                "5: Rotation CW R"
            ]),
            new Series("Hou ou tek", [
                "Hou Nan Tek R + Jeet Tek L + Nan Tek L",
                "Hou Nan Tek R + Juk Tek L + Nan Tek L",
                "Hou Nan Tek R + Gwa Tek L + Nan Tek L",
                "Hou Nan Tek R + Jun Juk Tek R + Nan Tek L",
                "Hou Nan Tek R + Jun Gwa Tek R + Nan Tek L",
                "Hou Nan Tek R + Jun So Tek R + Nan Tek L"
            ]),
            new Series("18 Kicks", [
                "Jeet Tek L",
                "Hou Jeet Tek R",
                "Jik Tek L",
                "Hou Jik Tek R",
                "Nan Tek L",
                "Hou Nan Tek R",
                "Juk Tek L",
                "Hou Juk Tek R",
                "Gwa Tek L",
                "Hou Gwa Tek R",
                "So Tek L",
                "Hou So Tek R",
                "Jun Juk Tek R",
                "Hou Jun Juk Tek L",
                "Jun Gwa Tek R",
                "Hou Jun Gwa Tek L",
                "Jun So Tek R",
                "Hou Jun So Tek L"
            ]),
            new Series("Loyda JFK", [
                "Jab L"
            ]),
            new Series("Ping Chui Laop Sao Gwa Chui series", [
                "Low line Hit L -> Vertical Locking L + Pak Sao R + Jab L -> Through Locking R + Bong Sao L + Lop Sao R + Gwa Chuie L",
                "Low line Hit L -> Vertical Locking L + Pak Sao R + Jab L -> Through Locking R + Bong Sao L + Lop Sao R + Gwa Chuie L",
                "Low line Hit L -> Vertical Locking L + Pak Sao R + Jab L -> Vertical Locking R + Pak Sao R + Jab L -> Through Locking + Bong Sao L + Lop Sao R + Gwa Chuie L",
                "Low line Hit L -> Vertical Locking L + Pak Sao R + Jab L -> Vertical Locking L + Pak Sao R + Jab L -> Through Locking R + Bong Sao L + Lop Sao R + Da L",
                "Low line Hit L -> Vertical Locking L + Pak Sao R + Jab L -> Vertical Locking R + Pak Sao R + Jab L -> Through Locking R + Bong Sao L + Pak Sao L + Lop Sao R + Da L"
            ]),
            new Series("22 Coups de poings", [
                "Jab L",
                "Cross R",
                "Body Hook R",
                "Body Hook L",
                "Uppercut R",
                "Uppercut L",
                "Hook R",
                "Hook L",
                "Body Jab L",
                "Body Cross R",
                "Swing R",
                "Swing L",
                "OverHead R",
                "Uppercut L",
                "OverHead L",
                "Uppercut R",
                "Qua Chuie / cross R",
                "Qua Chuie / Jab L",
                "Frappes Marteau R",
                "Frappes Marteau L",
                "overhead poing avant R",
                "overhead poing arrière L"
            ]),
            new Series("Sinawali series", [
                "Cob Cob + Pay Pay + Ikis + H L H + Dos Ikis + H L (Through) + Even Six Heaven + Even Six Standard + Even Six Earth + Umbrella Heaven + Umbrella Standard + Umbrella Earth + Backend Six Heaven + Backend Six Standard + Backend Six Earth + Upword Six count + Ordabis Motion + Sang Kite"
            ]),
            new Series("Trapping 9 entrées de base", [
                "Pak Sao R + Jab L",
                "Pak Sao R + Jab L -> Vertical Locking L + Pak Sao R + Jab L",
                "Pak Sao R + Jab L -> Catch Arm L + Jab R + Pak Sao R + Jab L",
                "Pak Sao R + Jab L -> Vertical Locking L + Tan Sao L + Pak Sao R + Jab L"
            ])
        ];
    }
}
