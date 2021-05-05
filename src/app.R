library(shiny)
library(ggplot2)

# results <- read.csv("../data/bayesian_results_df.csv")
# results <- results[3:nrow(results)-1,]
# player_names <- read.csv("../data/player_index_map.csv")
# results$names <- player_names$player_name
# priors_vet <- read.csv("../data/Ridge_Priors+SE_2017_nonrookie.csv")
# priors_rookie <- read.csv("../data/Ridge_Priors+SE_2017_rookie.csv")
# priors_all <- rbind(priors_vet, priors_rookie)
# results_merged <- merge(results, priors_all, by.x = "names", by.y = "name")
# results <- results_merged[,c("names", "Team", "mean", "sd.x", "finalpriors")]
# names(results) <- c("Name", "Team", "Rating", "SD", "Prior")

#Read and format results
results_16 <- read.csv("../data/bayesian_results_df_2015_16.csv")
results_17 <- read.csv("../data/bayesian_results_df_2016_17.csv")
results_18 <- read.csv("../data/bayesian_results_df_2017_18.csv")
results_16 <- results_16[3:nrow(results_16)-1,]
results_17 <- results_17[3:nrow(results_17)-1,]
results_18 <- results_18[3:nrow(results_18)-1,]

#Read and format indices, add to results
player_names_16 <- read.csv("../data/player_index_map_2015-16.csv")
player_names_17 <- read.csv("../data/player_index_map_2016-17.csv")
player_names_18 <- read.csv("../data/player_index_map_2017-18.csv")
results_16$names <- player_names_16$player_name
results_17$names <- player_names_17$player_name
results_18$names <- player_names_18$player_name

#read and format priors 2015-2016
priors_vet_16 <- read.csv("../data/final_priors_vets_2015_16.csv")
priors_rookie_16 <- read.csv("../data/final_priors_rookies_2015_16.csv")
priors_all_16 <- rbind(priors_vet_16, priors_rookie_16)
results_merged_16 <- merge(results_16, priors_all_16, 
                           by.x = "names", by.y = "name")
results_16 <- 
  results_merged_16[,c("names", "Team", "mean", "sd.x", "finalpriors")]
names(results_16) <- c("Name", "Team", "Rating", "SD", "Prior")

#read and format priors 2016-2017
priors_vet_17 <- read.csv("../data/final_priors_vets_2016_17.csv")
priors_rookie_17 <- read.csv("../data/final_priors_rookies_2016_17.csv")
priors_all_17 <- rbind(priors_vet_17, priors_rookie_17)
results_merged_17 <- merge(results_17, priors_all_17, 
                           by.x = "names", by.y = "name")
results_17 <- 
  results_merged_17[,c("names", "Team", "mean", "sd.x", "finalpriors")]
names(results_17) <- c("Name", "Team", "Rating", "SD", "Prior")

#read and format priors 2017-2018
priors_vet_18 <- read.csv("../data/final_priors_vets_2017_18.csv")
priors_rookie_18 <- read.csv("../data/final_priors_rookies_2017_18.csv")
priors_all_18 <- rbind(priors_vet_18, priors_rookie_18)
results_merged_18 <- merge(results_18, priors_all_18, 
                           by.x = "names", by.y = "name")
results_18 <- 
  results_merged_18[,c("names", "Team", "mean", "sd.x", "finalpriors")]
names(results_18) <- c("Name", "Team", "Rating", "SD", "Prior")

#format data for times series
results_16$Year <- rep(2016, nrow(results_16))
results_17$Year <- rep(2017, nrow(results_17))
results_18$Year <- rep(2018, nrow(results_18))
all_players <- rbind(results_16, results_17, results_18)
all_players <- all_players[,c("Name", "Year", "Rating")]


ui <- fluidPage(
  
  # App title ----
  titlePanel("NBA Posterior Estimates"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: dropdown to select plot ----
      selectInput(
        inputId = "select_season",
        label = "Select Season",
        choices = c('2015-2016', '2016-2017', '2017-2018'),
        selected = NULL,
        multiple = FALSE,
        selectize = FALSE,
        width = NULL,
        size = NULL
      ),
      conditionalPanel(
        condition = "input.select_season == '2015-2016'",
        selectInput(
          inputId = "select_players_16",
          label = "Select Player",
          choices = results_16$Name,
          selected = NULL,
          multiple = TRUE,
          selectize = TRUE,
          width = NULL,
          size = NULL
        )
      ),
      conditionalPanel(
        condition = "input.select_season == '2016-2017'",
        selectInput(
          inputId = "select_players_17",
          label = "Select Player",
          choices = results_17$Name,
          selected = NULL,
          multiple = TRUE,
          selectize = TRUE,
          width = NULL,
          size = NULL
        )
      ),
      conditionalPanel(
        condition = "input.select_season == '2017-2018'",
        selectInput(
          inputId = "select_players_18",
          label = "Select Player",
          choices = results_18$Name,
          selected = NULL,
          multiple = TRUE,
          selectize = TRUE,
          width = NULL,
          size = NULL
        )
      ),
      selectInput(
        inputId = "select_players_timeline",
        label = "Select Player (Time Series)",
        choices = unique(all_players$Name),
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
      plotOutput("player_timeline"),
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
  #select results

    
  #gather data
  output$plot <- renderPlot({
    if(input$select_season == '2015-2016') {
      results = results_16
      filtered_res <- results[results$Name %in% input$select_players_16,]
      xlow = min(filtered_res$Rating - 3*filtered_res$SD) - 0.5
      xhigh = max(filtered_res$Rating + 3*filtered_res$SD) + 0.5
      g <- ggplot(filtered_res) +
        xlim(xlow,xhigh)
    }
    else if (input$select_season == '2016-2017'){
      results = results_17
      filtered_res <- results[results$Name %in% input$select_players_17,]
      xlow = min(filtered_res$Rating - 3*filtered_res$SD) - 0.5
      xhigh = max(filtered_res$Rating + 3*filtered_res$SD) + 0.5
      g <- ggplot(filtered_res) +
        xlim(xlow,xhigh)
    }
    else {
      results = results_18
      filtered_res <- results[results$Name %in% input$select_players_18,]
      xlow = min(filtered_res$Rating - 3*filtered_res$SD) - 0.5
      xhigh = max(filtered_res$Rating + 3*filtered_res$SD) + 0.5
      g <- ggplot(filtered_res) +
        xlim(xlow,xhigh)
    }
    
    #normal dist output
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
  
  output$player_timeline <- renderPlot({
    filtered_timeline <- 
      all_players[all_players$Name %in% input$select_players_timeline,]
    ggplot(filtered_timeline, aes(Year, Rating, color = Name)) + geom_line() + 
      ggtitle("Player Ratings by Season")
  })
  
  output$plot_scatter <- renderPlot({
    if(input$select_season == '2015-2016') results = results_16
    else if (input$select_season == '2016-2017') results = results_17
    else results = results_18
    ggplot(results, aes(Prior, Rating, color = Team)) + geom_point() + 
      ggtitle("Player Ratings by Prior Estimates")
  })
  
  output$click_info <- renderPrint({
    if(input$select_season == '2015-2016') results = results_16
    else if (input$select_season == '2016-2017') results = results_17
    else results = results_18
    # Because it's a ggplot2, we don't need to supply xvar or yvar; if this
    # were a base graphics plot, we'd need those.
    nearPoints(results, input$plot_scatter_click, addDist = TRUE)
  })
  
  output$brush_info <- renderPrint({
    if(input$select_season == '2015-2016') results = results_16
    else if (input$select_season == '2016-2017') results = results_17
    else results = results_18
    brushedPoints(results, input$plot_scatter_brush)
  })
  
}


shinyApp(ui = ui, server = server)
