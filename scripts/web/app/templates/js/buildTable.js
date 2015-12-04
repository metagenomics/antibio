
var OVERVIEW_TXT_PATH = "overview_new.txt",
    INDEX_PATH = "index",
    linkFormatter = function (value, row) {
    var path = window.location.href + "/../" + row['Gene ID'] + ".html";
    return '<a href=' + path + '>' + value + '</a>';
}, seqFormatter = function (value, row, idx) {
        var viewer = '<button class=" inspect-seq btn btn-sm btn-primary">Inspect Sequence</button>',
            sequence = '<button class=" show-seq btn btn-sm btn-primary">Show Sequence</button>',
            isViewerMode = $("#pileup").length;

        return '<div id="'+ idx +'">' +
            (isViewerMode ? viewer + '<br>' + sequence : sequence) +
        '</div>';
}, setUpNavbar = function () {

    var navbar = $('#navbar-main'),
        distance = navbar.offset().top,
        $window = $(window);

    $window.scroll(function () {
        if ($window.scrollTop() >= distance) {
            navbar.removeClass('navbar-fixed-top').addClass('navbar-fixed-top');
            $("body").css("padding-top", "70px");
        } else {
            navbar.removeClass('navbar-fixed-top');
            $("body").css("padding-top", "0px");
        }
    });
};

d3.tsv(OVERVIEW_TXT_PATH, function (error, data) {

    var table = $('#table'),
        index = new function(){
            var indexData = {},
                tsv = d3.tsv;
            this.processIndex = function(path, func){
                if(Object.keys(indexData).length == 0) {
                    tsv(path, function (error, data) {
                        data.forEach(function (d) {
                            indexData[d["fix_name"]] = d;
                        });
                        func(indexData)
                    });
                } else {
                    func(indexData)
                }
            }
        },
        isInRange = function (lower, value) {
            var lowerPoint = lower * 10,
                upperPoint = lower * 10 + 10;

            if (value > lowerPoint && value <= upperPoint) {
                return true;
            } else {
                return false;
            }
        },
        onBarClick = function (d, element) {
            var lowerPoint = d.index,
                isSelected = d3.select(element).classed("_selected_");
            if (!isSelected) {
                $('#table').bootstrapTable('load', data);
            } else {
                $('#table').bootstrapTable('load', $.grep(data, function (row) {
                    return isInRange(lowerPoint, row["Identity"]);
                }));
            }
        },
        currRow = "",
        aggregateData = function (data) {

            var aggregation = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

            for (var i in data) {
                var id = data[i].Identity;
                switch (true) {
                    case id <= 10:
                        aggregation[0]++;
                        break;
                    case id <= 20:
                        aggregation[1]++;
                        break;
                    case id <= 30:
                        aggregation[2]++;
                        break;
                    case id <= 40:
                        aggregation[3]++;
                        break;
                    case id <= 50:
                        aggregation[4]++;
                        break;
                    case id <= 60:
                        aggregation[5]++;
                        break;
                    case id <= 70:
                        aggregation[6]++;
                        break;
                    case id <= 80:
                        aggregation[7]++;
                        break;
                    case id <= 90:
                        aggregation[8]++;
                        break;
                    case id <= 100:
                        aggregation[9]++;
                        break;
                    default:
                        break;
                }
            }
            return aggregation;
        },
        headerColumns = $.map(Object.keys(data[0]),
            function (val) {
                if (val == "Best blastp hit") {
                    return "<th data-filter-control='input' data-formatter='linkFormatter' data-field='" + val + "' data-sortable='true' >" + val + "</th>";
                } else if (val == "Subject titles") {
                    return "<th data-filter-control='input' class='title-col' data-field='" + val + "' data-sortable='true' >" + val + "</th>";
                } else if (val == "Gene sequence") {
                    return "<th data-formatter='seqFormatter' data-filter-control='input' class='seq-col' data-field='" + val + "' data-sortable='true' >" + val + "</th>";
                } else {
                    return "<th data-filter-control='input' data-align='center' data-field='" + val + "' data-sortable='true' >" + val + "</th>";
                }
            }), transformedData = aggregateData(data),
        xAxis = ['x', '0-10', '10-20', '20-30', '30-40', '40-50', '50-60', '60-70', '70-80', '80-90', '90-100'];

    transformedData.unshift("data");
    table.find("tr").html(headerColumns);

    var chart = c3.generate({
        bindto: '#chart',
        data: {
            x: 'x',
            columns: [xAxis, transformedData],
            type: 'bar',
            onclick: onBarClick,
            selection: {
                enabled: true,
                multiple: false
            }
        },
        axis: {
            x: {
                type: 'category',
                label: {
                    text: 'hits identity to pHMM [%]',
                    position: 'outer-right'
                }
            },
            y: {
                label: {
                    text: 'Number of hits',
                    position: 'outer-top'
                }
            }
        },
        bar: {
            width: {
                ratio: 0.5
            }
        }
    });

    $('table').on('click', '.show-seq', function (event) {
        currRow = data[$(event.target).parent().attr('id')];
        $('#showSeqModal').modal('show').find('#sequences-text').text(currRow['Gene sequence']);
    });

    $('table').on('click', '.inspect-seq', function (event) {
        index.processIndex(INDEX_PATH, function(indexData){
            var pileupDiv = $('#pileup'),
                indexRow = indexData[data[$(event.target).parent().attr('id')]['Gene ID']],
                contigId = indexRow['contig_id'],
                bitNum = indexRow['bitNum'],
                faaStart = indexRow['faaStart'],
                faaStop = indexRow['faaStop'],
                twoBit = pileup.formats.twoBit({
                    url: "fa." + bitNum
                }),
                genes = pileup.formats.bigBed({
                    url: contigId + ".bb"
                });

                pileupDiv.empty();
                pileup.create(pileupDiv.get(0), {
                    range: {contig: contigId, start: parseInt(faaStart), stop: parseInt(faaStop)},
                    tracks: [
                        {
                            viz: pileup.viz.genome(),
                            isReference: true,
                            data: twoBit,
                            name: 'Reference'
                        },
                        {
                            viz: pileup.viz.scale(),
                            name: 'Scale'
                        },
                        {
                            viz: pileup.viz.location(),
                            name: 'Location'
                        },
                        {
                            viz: pileup.viz.genes(),
                            data: genes,
                            name: 'Genes'
                        }
                    ]
                });

        });
    });

    table.bootstrapTable({data: data});

    setUpNavbar();
});