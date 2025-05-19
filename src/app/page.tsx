import Image from "next/image";

export default function Home() {
  return (
    <div className="min-h-[80vh] flex flex-col items-center justify-center text-center">
      <h1 className="text-4xl sm:text-5xl md:text-6xl font-bold text-orange-800 mb-6">
        Welcome to Movefully
      </h1>
      <p className="text-xl text-orange-700 mb-8 max-w-2xl">
        Making fitness simple, accessible, and focused on your overall well-being.
      </p>
      <div className="space-x-4">
        <button className="bg-orange-500 hover:bg-orange-600 text-white font-semibold py-3 px-6 rounded-lg transition-colors">
          Get Started
        </button>
        <button className="border-2 border-orange-500 text-orange-600 hover:bg-orange-50 font-semibold py-3 px-6 rounded-lg transition-colors">
          Learn More
        </button>
      </div>
    </div>
  );
}
