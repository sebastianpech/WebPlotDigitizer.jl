using Plots
using Dates

lay = @layout [a{0.2h}
               [grid(3,1) e]]
plot(legend=:none,layout=lay,
    plot([Date(2020,1,1), Date(2020,1,3), Date(2020,2,1), Date(2020,2,13)], [7, 2, 3, 1]),
    plot([0, 1, 3, 5], [7, 2, 3, 1]),
    plot([1, 10, 100, 1000],[7,2,3,1],xaxis=:log),
    bar([10,2,5,11]),
    plot([0,0.3,0.6,0.7]*2π,[1,2,3,2],proj=:polar), dpi=600)
savefig("test.png")

x1 = [Time(10,1,3), Time(10,2,3), Time(11,3,4), Time(13,10,3)]
y1 = [1, 10, -3, 3]
x2 = Date(2020,9,1) .+ x1
y2 = [-1, 6, 3, -10]
plot(layout=grid(2,1),
    plot(x1,y1),
    plot(x2,y2),dpi=600)

savefig("test.png")
