library(shiny)
library(ggplot2)

results <- read.csv("../data/bayesian_results_df.csv")
results <- results[3:nrow(results)-1,]
player_names <- read.csv("../data/player_index_map.csv")
results$names <- player_names$player_name


ui <- fluidPage(
  
  # App title ----
  titlePanel("NBA Posterior Esimates"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: dropdown to select plot ----
      selectInput(
        inputId = "select_players",
        label = "Select Player",
        choices = results$names,
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
      plotOutput(outputId = "plot")
      
    )
  )
)

server <- function(input, output) {
  
  #gather data
  output$plot <- renderPlot({
    filtered_res <- results[results$name %in% input$select_players,]
    xlow = min(filtered_res$mean - 3*filtered_res$sd) - 0.5
    xhigh = max(filtered_res$mean + 3*filtered_res$sd) + 0.5
    color_seq <- 1:nrow(filtered_res)
    names(color_seq) <- input$select_players
    
    
   g <- ggplot(filtered_res, aes(col = filtered_res$name)) +
    xlim(xlow,xhigh) +
    mapply(function(mean, sd, col) {
      stat_function(fun = dnorm, args = list(mean = mean, sd = sd), col = col)
    },
    mean = filtered_res$mean,
      sd = filtered_res$sd,
      col = c(1:nrow(filtered_res))
    )
      #+ scale_color_manual(values = color_seq)
    
    
    # g <- ggplot(filtered_res) + 
    #   xlim(xlow,xhigh)
    # for(i in 1:nrow(filtered_res))
    # {
    #   g <- g + stat_function(fun = dnorm, 
    #                          args = list(mean = filtered_res$mean[i], 
    #                                      sd = filtered_res$sd[i]),
    #                          aes(colour = filtered_res$name))
    # }
    # g <- g + scale_colour_manual("Player", values = c(1:nrow(filtered_res)))
    #+ scale_color_manual(values = color_seq)
    
    g
    })
  
}


shinyApp(ui = ui, server = server)
