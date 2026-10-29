.pragma library

// Single source of truth for the charging animation catalog.
// Each group is shown as one entry in the "Animation family" selector, so the
// style list never grows into an endless scroll: only the styles of the
// selected family are listed at once (seven at most).
var groups = [
    {
        name: "Classic",
        styles: [
            { text: "Sweep", value: "sweep" },
            { text: "Double sweep", value: "double" },
            { text: "Moving stripes", value: "stripes" }
        ]
    },
    {
        name: "Fluid glow",
        styles: [
            { text: "Breathing", value: "pulse" },
            { text: "Bright halo", value: "glow" },
            { text: "Liquid wave", value: "wave" }
        ]
    },
    {
        name: "Electric",
        styles: [
            { text: "Thunderstorm", value: "bolt" },
            { text: "Lightning", value: "lightning" },
            { text: "Heartbeat", value: "heartbeat" }
        ]
    },
    {
        name: "Traveling light",
        styles: [
            { text: "Comet", value: "comet" },
            { text: "Twin comet", value: "twin" },
            { text: "Snake", value: "snake" },
            { text: "Orbit", value: "orbit" },
            { text: "Spiral", value: "spiral" },
            { text: "Pendulum", value: "pendulum" },
            { text: "Scanner", value: "scanner" }
        ]
    },
    {
        name: "Outline neon",
        styles: [
            { text: "Perimeter neon", value: "neon" },
            { text: "Twin neon", value: "neon2" },
            { text: "Neon wave", value: "neonwave" },
            { text: "Perimeter bolt", value: "neonbolt" },
            { text: "Neon spin", value: "neonspin" }
        ]
    },
    {
        name: "Ambient",
        styles: [
            { text: "Firefly", value: "firefly" },
            { text: "Ripple", value: "ripple" },
            { text: "Aurora", value: "aurora" },
            { text: "Matrix", value: "matrix" }
        ]
    }
]

function values() {
    var all = [];
    for (var g = 0; g < groups.length; g++) {
        for (var i = 0; i < groups[g].styles.length; i++) {
            all.push(groups[g].styles[i].value);
        }
    }
    return all;
}

function groupIndexForStyle(style) {
    for (var g = 0; g < groups.length; g++) {
        for (var i = 0; i < groups[g].styles.length; i++) {
            if (groups[g].styles[i].value === style) {
                return g;
            }
        }
    }
    return 0;
}

function labelForStyle(style) {
    for (var g = 0; g < groups.length; g++) {
        for (var i = 0; i < groups[g].styles.length; i++) {
            if (groups[g].styles[i].value === style) {
                return groups[g].styles[i].text;
            }
        }
    }
    return "Sweep";
}
