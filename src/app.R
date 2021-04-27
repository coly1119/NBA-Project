library(shiny)
library(ggplot2)

results <- read.csv("../data/bayesian_results_df.csv")
results <- results[3:nrow(results)-1,]
player_names <- read.csv("../data/player_index_map.csv")
results$names <- player_names$player_name
priors_vet <- read.csv("../data/Ridge_Priors+SE_2017_nonrookie.csv")
priors_rookie <- read.csv("../data/Ridge_Priors+SE_2017_rookie.csv")
priors_all <- rbind(priors_vet, priors_rookie)
results_merged <- merge(results, priors_all, by.x = "names", by.y = "name")
results <- results_merged[,c("names", "Team", "mean", "sd.x", "finalpriors")]
names(results) <- c("Name", "Team", "Rating", "SD", "Prior")


ui <- fluidPage(
  
  # App title ----
  titlePanel("NBA Posterior Estimates"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: dropdown to select plot ----
      selectInput(
        inputId = "select_players",
        label = "Select Player",
        choices = results$Name,
        selected = NULL,
        multiple = TRUE,
        selectize = TRUE,
        width = NULL,
        size = NULL
      )
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Histogram ----
      plotOutput(outputId = "plot"),
      fluidRow(
        column(width = 4,
               plotOutput("plot_scatter", height = 900, width = 1200,
                          click = "plot_scatter_click",
                          brush = brushOpts(
                            id = "plot_scatter_brush"
                          )
               )
        )
      ),
      fluidRow(
        column(width = 6,
               h4("Selected Player (Click)"),
               verbatimTextOutput("click_info")
        ),
        column(width = 6,
               h4("Selected Player(s) (Brush)"),
               verbatimTextOutput("brush_info")
        )
      )
      
    )
  )
)

server <- function(input, output) {
  
  #gather data
  output$plot <- renderPlot({
    filtered_res <- results[results$Name %in% input$select_players,]
    xlow = min(filtered_res$Rating - 3*filtered_res$SD) - 0.5
    xhigh = max(filtered_res$Rating + 3*filtered_res$SD) + 0.5
    color_seq <- 1:nrow(filtered_res)
    names(color_seq) <- input$select_players
    
    
   # g <- ggplot() + 
   #  xlim(xlow,xhigh) +
   #  mapply(function(mean, sd, col) {
   #    stat_function(fun = dnorm, args = list(mean = mean, sd = sd), col = col)
   #  },
   #    mean = filtered_res$Rating,
   #    sd = filtered_res$SD,
   #    col = c(1:nrow(filtered_res))
   #  )
      #+ scale_color_manual(values = color_seq)
    
    
    g <- ggplot(filtered_res) +
      xlim(xlow,xhigh)
    if(nrow(filtered_res > 0))
    {
      
      for(i in 1:nrow(filtered_res))
      {
        g <- g + stat_function(fun = dnorm,
                               args = list(mean = filtered_res$Rating[i],
                                           sd = filtered_res$SD[i]),
                               aes(color = !!filtered_res$Name[i]))
      }
    }
    g <- g + labs(color='Player') + 
      ggtitle("Player Rating Distributions")
    
    g
    })
  
  output$plot_scatter <- renderPlot({
    ggplot(results, aes(Prior, Rating, color = Team)) + geom_point() + 
      ggtitle("Player Ratings by Prior Estimates")
  })
  
  output$click_info <- renderPrint({
    # Because it's a ggplot2, we don't need to supply xvar or yvar; if this
    # were a base graphics plot, we'd need those.
    nearPoints(results, input$plot_scatter_click, addDist = TRUE)
  })
  
  output$brush_info <- renderPrint({
    brushedPoints(results, input$plot_scatter_brush)
  })
  
}


shinyApp(ui = ui, server = server)
