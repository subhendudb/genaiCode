const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: './src/index.js', // Entry point of your app
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'main.js',
    clean: true, // Clean the output directory before emit
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/, // For .js and .jsx files
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
      {
        test: /\.css$/, // For CSS imports
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(png|jpg|jpeg|gif|svg)$/i, // For images
        type: 'asset/resource',
      },
    ],
  },
  resolve: {
    extensions: ['.js', '.jsx'], // So you can import without specifying extension
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: './public/index.html', // Use your public/index.html as template
    }),
  ],
  devServer: {
    static: {
      directory: path.join(__dirname, 'public'), // Serve static files from public
    },
    compress: true,
    port: 8080,
    historyApiFallback: true, // For React Router
    hot: true,
    open: true,
  },
  mode: 'development', // or 'production'
  devtool: 'source-map', // For easier debugging
};
