library(shiny)
library(plotly)
library(ggplot2)

# results <- read.csv("data/bayesian_results_df.csv")
# results <- results[3:nrow(results)-1,]
# player_names <- read.csv("data/player_index_map.csv")
# results$names <- player_names$player_name
# priors_vet <- read.csv("data/Ridge_Priors+SE_2017_nonrookie.csv")
# priors_rookie <- read.csv("data/Ridge_Priors+SE_2017_rookie.csv")
# priors_all <- rbind(priors_vet, priors_rookie)
# results_merged <- merge(results, priors_all, by.x = "names", by.y = "name")
# results <- results_merged[,c("names", "Team", "mean", "sd.x", "finalpriors")]
# names(results) <- c("Name", "Team", "Rating", "SD", "Prior")

#Read and format results
results_16 <- read.csv("data/bayesian_results_df_2015_16.csv")
results_17 <- read.csv("data/bayesian_results_df_2016_17.csv")
results_18 <- read.csv("data/bayesian_results_df_2017_18.csv")
results_16 <- results_16[3:nrow(results_16)-1,]
results_17 <- results_17[3:nrow(results_17)-1,]
results_18 <- results_18[3:nrow(results_18)-1,]

#Read and format indices, add to results
player_names_16 <- read.csv("data/player_index_map_2015-16.csv")
player_names_17 <- read.csv("data/player_index_map_2016-17.csv")
player_names_18 <- read.csv("data/player_index_map_2017-18.csv")
results_16$names <- player_names_16$player_name
results_17$names <- player_names_17$player_name
results_18$names <- player_names_18$player_name

#read and format priors 2015-2016
priors_vet_16 <- read.csv("data/final_priors_vets_2015_16.csv")
priors_rookie_16 <- read.csv("data/final_priors_rookies_2015_16.csv")
priors_all_16 <- rbind(priors_vet_16, priors_rookie_16)
results_merged_16 <- merge(results_16, priors_all_16, 
                           by.x = "names", by.y = "name")
results_16 <- 
  results_merged_16[,c("names", "Team", "mean", "sd.x", "finalpriors")]
names(results_16) <- c("Name", "Team", "Rating", "SD", "Prior")

#read and format priors 2016-2017
priors_vet_17 <- read.csv("data/final_priors_vets_2016_17.csv")
priors_rookie_17 <- read.csv("data/final_priors_rookies_2016_17.csv")
priors_all_17 <- rbind(priors_vet_17, priors_rookie_17)
results_merged_17 <- merge(results_17, priors_all_17, 
                           by.x = "names", by.y = "name")
results_17 <- 
  results_merged_17[,c("names", "Team", "mean", "sd.x", "finalpriors")]
names(results_17) <- c("Name", "Team", "Rating", "SD", "Prior")

#read and format priors 2017-2018
priors_vet_18 <- read.csv("data/final_priors_vets_2017_18.csv")
priors_rookie_18 <- read.csv("data/final_priors_rookies_2017_18.csv")
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
teams <- sort(unique(results_16$Team))
teams <- c("All Teams", teams)

#samples data for matrix
samples_16 <- read.csv("data/bayesian_posterior_samples_2015_16.csv")
samples_16 <- samples_16[, -1]
names(samples_16) <- player_names_16$player_name

samples_17 <- read.csv("data/bayesian_posterior_samples_2016_17.csv")
samples_17 <- samples_17[, -1]
names(samples_17) <- player_names_17$player_name

samples_18 <- read.csv("data/bayesian_posterior_samples_2017_18.csv")
samples_18 <- samples_18[, -1]
names(samples_18) <- player_names_18$player_name


ui <- navbarPage("NBA Project Visualizations with BCPM Rating",
        tabPanel("Player Distributions",
          titlePanel("NBA Player Distributions According to BCPM"),
          sidebarLayout(
            # Sidebar panel for inputs ----
            sidebarPanel(
              p("User Selects Season and Players. Player distribution, assumed 
                to be normal, is displayed. Mean and Standard Deviation 
                from our BCPM model."),
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
            )
          ),
          mainPanel(
            plotOutput(outputId = "plot"),
          )
        )
      ),
      tabPanel("Mean Rating by Season",
               titlePanel("Mean BCPM Rating by Season"),
               sidebarLayout(
                 
                 # Sidebar panel for inputs ----
                 sidebarPanel(
                   p("User selects Players. Player Ratings from our BCPM model 
                     are displayed as a time series across 3 
                     different seasons."),
                   selectInput(
                     inputId = "select_players_timeline",
                     label = "Select Player(s)",
                     choices = unique(all_players$Name),
                     selected = NULL,
                     multiple = TRUE,
                     selectize = TRUE,
                     width = NULL,
                     size = NULL
                   )
                 ),
                 mainPanel(
                   plotlyOutput(outputId = "player_timeline")
                 )
               )
      ),
      tabPanel("Ratings by Prior",
               titlePanel("BCPM Player Rating by Contract Prior"),
               sidebarLayout(
                 
                 # Sidebar panel for inputs ----
                 sidebarPanel(
                   p("User selects Season and Team. Displays a scatterplot 
                     of our final BCPM Rating against Contract prior
                     used to train the model."),
                   selectInput(
                     inputId = "select_season_s",
                     label = "Select Season",
                     choices = c('2015-2016', '2016-2017', '2017-2018'),
                     selected = NULL,
                     multiple = FALSE,
                     selectize = FALSE,
                     width = NULL,
                     size = NULL
                   ),
                   selectInput(
                     inputId = "select_team",
                     label = "Select Team",
                     choices = teams,
                     selected = NULL,
                     multiple = FALSE,
                     selectize = FALSE,
                     width = NULL,
                     size = NULL
                   )
                 ),
                 mainPanel(
                   plotlyOutput("plot_scatter", height = 900, width = 1200)
                 )
               )
      ),
      tabPanel("Player Matrix",
               titlePanel("NBA Player Comparisons"),
               sidebarLayout(
                 
                 # Sidebar panel for inputs ----
                 sidebarPanel(
                   p("User selects Season and Players. 
                     Displays the probability that Player 1 (P1) is better than 
                     Player 2 (P2). Probability obtained by comparing 2000 
                     samples from relevant distributions given by BCPM model."),
                   selectInput(
                     inputId = "select_season_m",
                     label = "Select Season",
                     choices = c('2015-2016', '2016-2017', '2017-2018'),
                     selected = NULL,
                     multiple = FALSE,
                     selectize = FALSE,
                     width = NULL,
                     size = NULL
                   ),
                   conditionalPanel(
                     condition = "input.select_season_m == '2015-2016'",
                     selectInput(
                       inputId = "select_players_16_m",
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
                     condition = "input.select_season_m == '2016-2017'",
                     selectInput(
                       inputId = "select_players_17_m",
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
                     condition = "input.select_season_m == '2017-2018'",
                     selectInput(
                       inputId = "select_players_18_m",
                       label = "Select Player",
                       choices = results_18$Name,
                       selected = NULL,
                       multiple = TRUE,
                       selectize = TRUE,
                       width = NULL,
                       size = NULL
                     )
                   )
                 ),
                 mainPanel(
                   plotlyOutput(outputId = "matrix")
                 )
               )
      )
      
)

server <- function(input, output) {
  #normal dist output
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
    g <- g + labs(color='Player') + xlab("Rating") + ylab("Y")
    
    g
    })
  
  #timeline plot
  output$player_timeline <- renderPlotly({
    filtered_timeline <- 
      all_players[all_players$Name %in% input$select_players_timeline,]
    if(nrow(filtered_timeline) == 0){
      p <- ggplot(filtered_timeline, aes(Year, Rating, color = Name))
    }
    else{
    p <- ggplot(filtered_timeline, aes(Year, Rating, color = Name)) + 
      geom_line() + 
      geom_point() + 
      ggtitle("Player Ratings by Season") + 
      scale_x_continuous(breaks = c(2016,2017,2018),
                       labels = c("2016","2017","2018"))
    }
    ggplotly(p)
  })
  
  #scatter plot of rating vs prior
  output$plot_scatter <- renderPlotly({
    if(input$select_season_s == '2015-2016') results = results_16
    else if (input$select_season_s == '2016-2017') results = results_17
    else results = results_18
    if(input$select_team == "All Teams") results = results
    else{
      results = results[results$Team == input$select_team,]
    }
    p_scatter <- 
      ggplot(results, aes(Prior, Rating, label = SD, label2 = Name,
                          color = Team)) + geom_point() + 
      ggtitle("Player Ratings by Prior Estimates")
    ggplotly(p_scatter)
  })
  
  #probability matrix
  output$matrix <- renderPlotly({
    getPlayerProb <- function(player1, player2, samples){
      sum(samples[,player1] >= samples[,player2])/nrow(samples)
    }
    if(input$select_season_m == '2015-2016'){
      samples = samples_16
      selected_names = input$select_players_16_m
    } 
    else if (input$select_season_m == '2016-2017'){
      samples = samples_17
      selected_names = input$select_players_17_m
    }
    else {
      samples = samples_18
      selected_names = input$select_players_18_m
    }
    test <- data.frame(matrix(NA, nrow = length(selected_names)^2, ncol = 3))
    names(test) <- c("P1", "P2", "Probability")
    
    curr_row <- 1
    for(p1 in selected_names){
      for(p2 in selected_names){
        test[curr_row, "P1"] = p1
        test[curr_row, "P2"] = p2
        test[curr_row, "Probability"] = getPlayerProb(p1, p2, samples)
        curr_row = curr_row+1
      }
    }
    
    #test <- test[order(test$P2, test$P1, decreasing = TRUE), ]
    if(nrow(test) == 0) g <- ggplot(test, aes(x = P1, y = P2))
    else{
      g <-  ggplot(test, aes(x = P1, y = P2)) + 
        geom_tile(aes(fill = Probability)) + 
        theme(axis.text.x = element_text(angle = 90))
    }
    ggplotly(g)
  })
  
}


shinyApp(ui = ui, server = server)
